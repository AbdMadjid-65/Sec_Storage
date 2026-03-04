// ============================================================
// PriVault – Auth Provider (Riverpod)
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/core/encryption/encryption_service.dart';
import 'package:pri_vault/services/auth_service.dart';
import 'package:pri_vault/services/vault_service.dart';

// --- Providers ---

final authServiceProvider = Provider<AuthService>((ref) {
  final api = ref.read(apiClientProvider);
  final vault = VaultService();
  final encryption = EncryptionService();
  return AuthService(api, vault, encryption);
});

/// Current authentication state.
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref);
});

// --- State ---

enum AuthStatus { initial, authenticated, unauthenticated, requires2FA, loading }

class AuthState {
  final AuthStatus status;
  final Map<String, dynamic>? user;
  final String? pendingUserId; // For 2FA flow
  final String? resetToken;   // For password reset flow
  final String? error;
  final String? successMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.pendingUserId,
    this.resetToken,
    this.error,
    this.successMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    Map<String, dynamic>? user,
    String? pendingUserId,
    String? resetToken,
    String? error,
    String? successMessage,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        pendingUserId: pendingUserId ?? this.pendingUserId,
        resetToken: resetToken ?? this.resetToken,
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
    final api = _ref.read(apiClientProvider);
    final token = await api.getToken();
    if (token != null) {
      try {
        final profile = await api.get('/profiles/me');
        state = AuthState(status: AuthStatus.authenticated, user: profile);
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
    String accountType = 'regular',
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final authService = _ref.read(authServiceProvider);
      final result = await authService.signUp(
        email: email,
        password: password,
        accountType: accountType,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result['user'] as Map<String, dynamic>?,
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
        deviceFingerprint: deviceFingerprint,
        deviceType: 'mobile_app',
      );

      if (result['requires_2fa'] == true) {
        state = AuthState(
          status: AuthStatus.requires2FA,
          pendingUserId: result['user_id'] as String?,
        );
      } else {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: result['user'] as Map<String, dynamic>?,
        );
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> verify2FA({
    required String code,
    String? deviceFingerprint,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final authService = _ref.read(authServiceProvider);
      final result = await authService.verify2FA(
        userId: state.pendingUserId!,
        code: code,
        deviceFingerprint: deviceFingerprint,
        deviceType: 'mobile_app',
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result['user'] as Map<String, dynamic>?,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.requires2FA,
        pendingUserId: state.pendingUserId,
        error: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    final authService = _ref.read(authServiceProvider);
    await authService.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Send a password reset OTP to the user's email.
  Future<void> sendResetCode({required String email}) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final authService = _ref.read(authServiceProvider);
      final result = await authService.forgotPassword(email: email);
      state = AuthState(
        status: AuthStatus.unauthenticated,
        successMessage: result['message'] as String? ??
            'If an account with that email exists, a reset code has been sent.',
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  /// Verify the OTP code and receive a reset token.
  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final authService = _ref.read(authServiceProvider);
      final result = await authService.verifyResetCode(
        email: email,
        code: code,
      );
      state = AuthState(
        status: AuthStatus.unauthenticated,
        resetToken: result['reset_token'] as String?,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  /// Reset the password using the stored reset token.
  Future<void> resetPassword({required String newPassword}) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final authService = _ref.read(authServiceProvider);
      await authService.resetPassword(
        resetToken: state.resetToken!,
        newPassword: newPassword,
      );
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        successMessage: 'Password reset successfully. Please log in.',
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }
}
