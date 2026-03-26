// ============================================================
// PriVault – Vault Service
// ============================================================
// Handles secure local storage of sensitive keys/seeds.
// Persists master key seed to Firestore for cross-device access.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';

/// Secure storage service for PriVault.
class VaultService {
  final _secureStorage = const FlutterSecureStorage();
  final FirebaseFirestore _firestore;

  static const String _masterKeySeedKey = 'privault_master_key_seed';
  static const String _sharingPrivateKeyKey = 'privault_sharing_private_key';

  VaultService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Save the master key seed securely to local storage AND Firestore.
  Future<void> saveMasterKeySeed(String seed) async {
    await _secureStorage.write(key: _masterKeySeedKey, value: seed);
    // Also persist to Firestore so it survives reinstalls / device changes
    await _saveMasterKeySeedToFirestore(seed);
  }

  /// Persist the master key seed to Firestore users/{uid}.masterKeySeed.
  Future<void> _saveMasterKeySeedToFirestore(String seed) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set(
      {'masterKeySeed': seed},
      SetOptions(merge: true),
    );
  }

  /// Retrieve the master key seed with Firestore fallback.
  ///
  /// 1. Try local FlutterSecureStorage first.
  /// 2. If not found, fetch from Firestore users/{uid}.masterKeySeed.
  /// 3. If not in Firestore either, generate a new one and save to both.
  Future<String?> getMasterKeySeed() async {
    // 1. Try local cache
    final local = await _secureStorage.read(key: _masterKeySeedKey);
    if (local != null) return local;

    // 2. Try Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final firestoreSeed = doc.data()?['masterKeySeed'] as String?;

    if (firestoreSeed != null) {
      // Cache it locally for next time
      await _secureStorage.write(key: _masterKeySeedKey, value: firestoreSeed);
      return firestoreSeed;
    }

    // 3. Neither local nor Firestore — generate a new seed
    final newSeed = CryptoUtils.toBase64(CryptoUtils.generateKey());
    await _secureStorage.write(key: _masterKeySeedKey, value: newSeed);
    await _saveMasterKeySeedToFirestore(newSeed);
    return newSeed;
  }

  /// Save the sharing private key securely.
  Future<void> saveSharingPrivateKey(String privateKey) async {
    await _secureStorage.write(key: _sharingPrivateKeyKey, value: privateKey);
  }

  /// Retrieve the sharing private key securely.
  Future<String?> getSharingPrivateKey() async {
    return await _secureStorage.read(key: _sharingPrivateKeyKey);
  }

  /// Delete the sharing private key.
  Future<void> deleteSharingPrivateKey() async {
    await _secureStorage.delete(key: _sharingPrivateKeyKey);
  }

  /// Delete the master key seed securely.
  Future<void> deleteMasterKeySeed() async {
    await _secureStorage.delete(key: _masterKeySeedKey);
  }
}
