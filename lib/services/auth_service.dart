// ============================================================
// PriVault – Auth Service (Firebase)
// ============================================================
// Handles authentication via Firebase Auth + Firestore profiles.
// ============================================================

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pri_vault/core/encryption/key_derivation.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';
import 'package:pri_vault/core/encryption/encryption_service.dart';
import 'package:pri_vault/services/vault_service.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final VaultService _vault;
  final EncryptionService _encryptionService;

  AuthService(this._auth, this._firestore, this._vault, this._encryptionService);

  /// Sign up a new user securely.
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    String? phoneNumber,
    String accountType = 'regular',
  }) async {
    // 1. Create Firebase Auth account
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;

    // 2. Generate salt and derive master key (client-side)
    final salt = KeyDerivation.generateSalt();
    final masterKey = await KeyDerivation.deriveMasterKey(
      password: password,
      salt: salt,
    );

    // 3. Generate key pair for sharing
    final keyPair = await _encryptionService.generateKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKey = await keyPair.extractPrivateKeyBytes();

    // 4. Write user profile to Firestore (BR-01 required fields)
    final userDoc = {
      'uid': user.uid,
      'email': email,
      'displayName': null,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'photoURL': null,
      'accountType': accountType,
      'salt': CryptoUtils.toBase64(salt),
      'publicKey': CryptoUtils.toBase64(Uint8List.fromList(publicKey.bytes)),
      'plan': 'free',
      'storageUsedBytes': 0,
      'storageMaxBytes': 3221225472, // 3 GB free tier (BR-04)
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(user.uid).set(userDoc);

    // 5. Store Master Key and Private Key locally
    await _vault.saveMasterKeySeed(CryptoUtils.toBase64(masterKey));
    await _vault.saveSharingPrivateKey(
        CryptoUtils.toBase64(Uint8List.fromList(privateKey)),);

    return {
      'user': {
        'id': user.uid,
        'email': email,
        ...userDoc,
      },
    };
  }

  /// Sign in an existing user securely.
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    // 1. Authenticate via Firebase Auth
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;

    // 2. Read user profile from Firestore
    final profileDoc = await _firestore.collection('users').doc(user.uid).get();
    final profile = profileDoc.data() ?? {};

    // 3. Update last login
    await _firestore.collection('users').doc(user.uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });

    // 4. Derive master key from the salt in the profile
    final saltBase64 = profile['salt'] as String?;
    if (saltBase64 != null) {
      final salt = CryptoUtils.fromBase64(saltBase64);
      final masterKey = await KeyDerivation.deriveMasterKey(
        password: password,
        salt: salt,
      );
      await _vault.saveMasterKeySeed(CryptoUtils.toBase64(masterKey));
    }

    return {
      'user': {
        'id': user.uid,
        'email': email,
        ...profile,
      },
    };
  }

  /// Sign out and clear secure vault.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    try {
      await _vault.deleteMasterKeySeed();
      await _vault.deleteSharingPrivateKey();
    } catch (_) {}
  }

  /// Check if user is already authenticated.
  Future<bool> isAuthenticated() async {
    return _auth.currentUser != null;
  }

  /// Request a password-reset email via Firebase.
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
    return {
      'message': 'If an account with that email exists, a password reset link has been sent.',
    };
  }

  /// Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(code: 'ERROR_ABORTED_BY_USER', message: 'Sign in aborted by user');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    final profileDoc = await _firestore.collection('users').doc(user.uid).get();
    var profile = profileDoc.data() ?? {};

    if (!profileDoc.exists) {
      // New user
      final salt = KeyDerivation.generateSalt();
      final masterKey = await KeyDerivation.deriveMasterKey(
        password: user.uid, // Deterministic "password" for social logon
        salt: salt,
      );
      final keyPair = await _encryptionService.generateKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      final privateKey = await keyPair.extractPrivateKeyBytes();

      profile = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'accountType': 'personal',
        'salt': CryptoUtils.toBase64(salt),
        'publicKey': CryptoUtils.toBase64(Uint8List.fromList(publicKey.bytes)),
        'plan': 'free',
        'storageUsedBytes': 0,
        'storageMaxBytes': 3221225472, // 3 GB free tier (BR-04)
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('users').doc(user.uid).set(profile);
      
      await _vault.saveMasterKeySeed(CryptoUtils.toBase64(masterKey));
      await _vault.saveSharingPrivateKey(CryptoUtils.toBase64(Uint8List.fromList(privateKey)));
    } else {
      // Existing user
      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      final saltBase64 = profile['salt'] as String?;
      if (saltBase64 != null) {
        final salt = CryptoUtils.fromBase64(saltBase64);
        final masterKey = await KeyDerivation.deriveMasterKey(
          password: user.uid,
          salt: salt,
        );
        await _vault.saveMasterKeySeed(CryptoUtils.toBase64(masterKey));
      }
    }

    return {
      'user': {
        'id': user.uid,
        'email': user.email,
        ...profile,
      },
      'isNewUser': !profileDoc.exists,
    };
  }
}
