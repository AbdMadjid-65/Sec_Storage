// ============================================================
// PriVault – Key Derivation
// ============================================================
// Handles Argon2id master key derivation and HKDF sub-keys.
// ============================================================

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Key derivation functions for PriVault.
///
/// Security model:
///   1. User password + random salt → Argon2id → master key (256-bit)
///   2. Master key + domain info → HKDF → sub-key for each feature
///   3. Sub-keys are cached in encrypted Hive box or flutter_secure_storage
class KeyDerivation {
  /// Derive master key via Argon2id.
  static Future<Uint8List> deriveMasterKey({
    required String password,
    required Uint8List salt,
    int iterations = 3,
    int memoryKB = 65536,
    int parallelism = 4,
    int keyLength = 32,
  }) async {
    final kdf = Argon2id(
      memory: memoryKB,
      parallelism: parallelism,
      iterations: iterations,
      hashLength: keyLength,
    );

    final secretKey = await kdf.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );

    final bytes = await secretKey.extractBytes();
    return Uint8List.fromList(bytes);
  }

  /// Derive a sub-key via HKDF-SHA256.
  static Future<Uint8List> deriveSubKey({
    required Uint8List masterKey,
    required String info,
    int keyLength = 32,
  }) async {
    final hkdf = Hkdf(
      hmac: Hmac.sha256(),
      outputLength: keyLength,
    );

    final secretKey = SecretKey(masterKey);
    final derivedKey = await hkdf.deriveKey(
      secretKey: secretKey,
      info: utf8.encode(info),
    );

    final bytes = await derivedKey.extractBytes();
    return Uint8List.fromList(bytes);
  }

  /// Generate a fresh random salt.
  static Uint8List generateSalt({int length = 16}) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rng.nextInt(256)),
    );
  }
}
