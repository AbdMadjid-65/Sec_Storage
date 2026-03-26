// ============================================================
// PriVault – Firebase Providers & Helpers
// ============================================================
// Replaces the old HTTP API client with Firebase SDK providers.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase Auth instance provider.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Cloud Firestore instance provider.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});


/// Current authenticated user's UID. Returns null if not signed in.
String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

/// Current authenticated user's email.
String? get currentUserEmail => FirebaseAuth.instance.currentUser?.email;

/// Exception class (kept for compatibility with existing error handling).
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}
