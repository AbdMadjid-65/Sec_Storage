// ============================================================
// PriVault – Profile Provider (Riverpod + Firebase)
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pri_vault/repositories/profile_repository.dart';
import 'package:pri_vault/core/api/api_client.dart';

/// ProfileRepository provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final firestore = ref.read(firestoreProvider);
  return ProfileRepository(firestore);
});

/// Reactive auth UID provider — emits the current user's UID whenever auth
/// state changes (login / logout / account switch).
final _authUidProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((u) => u?.uid);
});

/// Current user's profile provider via Firestore real-time stream.
///
/// Rebuilds automatically whenever:
///   - The logged-in user changes (different UID on login)
///   - Any Firestore field changes (photo URL, display_name, etc.)
///   - The user logs out (emits null)
final userProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  // Watch auth UID — this re-creates the Firestore stream on user change.
  final uidAsync = ref.watch(_authUidProvider);
  final uid = uidAsync.valueOrNull;

  if (uid == null) return Stream.value(null);

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .doc(uid) // Always uses the CURRENT user's UID
      .snapshots()
      .map((doc) => doc.exists ? doc.data() : null);
});
