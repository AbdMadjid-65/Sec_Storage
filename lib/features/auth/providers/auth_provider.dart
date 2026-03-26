// ============================================================
// PriVault – Auth Provider (Riverpod + Firebase)
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/core/encryption/encryption_service.dart';
import 'package:pri_vault/services/auth_service.dart';
import 'package:pri_vault/services/vault_service.dart';
import 'package:pri_vault/features/auth/providers/profile_provider.dart';
import 'package:pri_vault/features/files/providers/files_provider.dart';
import 'package:pri_vault/features/dashboard/screens/dashboard_screen.dart';

// --- Providers ---

final authServiceProvider = Provider<AuthService>((ref) {
  final auth = ref.read(firebaseAuthProvider);
  final firestore = ref.read(firestoreProvider);
  final vault = VaultService();
  final encryption = EncryptionService();
  return AuthService(auth, firestore, vault, encryption);
});

/// Current authentication state.
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref);
});

// --- State ---

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final Map<String, dynamic>? user;
  final String? error;
  final String? successMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.successMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    Map<String, dynamic>? user,
    String? error,
    String? successMessage,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
        successMessage: successMessage,
      );
}

// --- Notifier ---

class AuthStateNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthStateNotifier(this._ref) : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        final profileDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        final profile = profileDoc.data() ?? {};
        state = AuthState(
          status: AuthStatus.authenticated,
          user: {'id': firebaseUser.uid, 'email': firebaseUser.email, ...profile},
        );
      } catch (_) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? phoneNumber,
    String accountType = 'personal',
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final authService = _ref.read(authServiceProvider);
      final result = await authService.signUp(
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        accountType: accountType,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result['user'] as Map<String, dynamic>?,
      );
      // BR-16: Audit log
      _ref.read(auditServiceProvider).log(action: 'auth.signup');
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.message ?? 'Registration failed',
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
    String? deviceFingerprint,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final authService = _ref.read(authServiceProvider);
      final result = await authService.signIn(
        email: email,
        password: password,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result['user'] as Map<String, dynamic>?,
      );
      // BR-16: Audit log
      _ref.read(auditServiceProvider).log(action: 'auth.login');
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.message ?? 'Sign in failed',
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  /// Whether the last Google sign-in was a brand-new user.
  bool _lastGoogleSignInWasNew = false;
  bool get lastGoogleSignInWasNew => _lastGoogleSignInWasNew;

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final authService = _ref.read(authServiceProvider);
      final result = await authService.signInWithGoogle();
      _lastGoogleSignInWasNew = result['isNewUser'] == true;
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result['user'] as Map<String, dynamic>?,
      );
      // BR-16: Audit log
      _ref.read(auditServiceProvider).log(
        action: _lastGoogleSignInWasNew ? 'auth.signup.google' : 'auth.login.google',
      );
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.message ?? 'Sign in failed',
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    // 1. Sign out from Firebase Auth.
    final authService = _ref.read(authServiceProvider);
    // BR-16: Audit log before signout clears the user
    _ref.read(auditServiceProvider).log(action: 'auth.logout');
    await authService.signOut();

    // 2. Invalidate ALL user-specific providers so no stale data
    //    persists when a different account logs in.
    _ref.invalidate(userProfileProvider);
    _ref.invalidate(storageUsageProvider);
    _ref.invalidate(deletedFilesProvider);
    _ref.invalidate(dashboardStatsProvider);
    _ref.invalidate(dashboardActivityProvider);

    // 3. Clear Hive user-specific cached data, but preserve
    //    app-level flags like hasSeenOnboarding.
    try {
      final settingsBox = Hive.box('settings');
      final hasSeenOnboarding = settingsBox.get('hasSeenOnboarding');
      await settingsBox.clear();
      if (hasSeenOnboarding == true) {
        await settingsBox.put('hasSeenOnboarding', true);
      }
    } catch (_) {}

    // 4. Reset auth state.
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Send a password reset email via Firebase.
  Future<void> sendResetCode({required String email}) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final authService = _ref.read(authServiceProvider);
      final result = await authService.forgotPassword(email: email);
      state = AuthState(
        status: AuthStatus.unauthenticated,
        successMessage: result['message'] as String? ??
            'If an account with that email exists, a reset link has been sent.',
      );
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.message ?? 'Failed to send reset email',
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }
}
