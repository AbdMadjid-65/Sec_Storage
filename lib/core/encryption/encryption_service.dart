// ============================================================
// PriVault – Encryption Service
// ============================================================
// This service handles:
//   - Argon2id master key derivation
//   - HKDF sub-key derivation for each feature domain
//   - XChaCha20-Poly1305 encrypt/decrypt
//   - Secure key storage via flutter_secure_storage
//
// Security design:
//   - Master key is derived on-device from user password + salt
//   - Sub-keys derived via HKDF with domain-specific info strings
//   - Nonces are generated fresh for every encryption operation
//   - Keys never leave the device; server only sees ciphertext
// ============================================================

import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:pri_vault/core/encryption/key_derivation.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';

/// Encryption service for PriVault.
class EncryptionService {
  /// Derive a master key from password and salt using Argon2id.
  Future<Uint8List> deriveMasterKey({
    required String password,
    required Uint8List salt,
  }) async {
    return KeyDerivation.deriveMasterKey(
      password: password,
      salt: salt,
    );
  }

  /// Derive a sub-key for a specific domain using HKDF.
  Future<Uint8List> deriveSubKey({
    required Uint8List masterKey,
    required String info,
  }) async {
    return KeyDerivation.deriveSubKey(
      masterKey: masterKey,
      info: info,
    );
  }

  /// Encrypt plaintext using XChaCha20-Poly1305.
  Future<Uint8List> encrypt({
    required Uint8List plaintext,
    required Uint8List key,
  }) async {
    final algorithm = Xchacha20.poly1305Aead();
    final secretKey = SecretKey(key);

    // Generate a 24-byte nonce for XChaCha20
    final nonce = CryptoUtils.generateNonce(24);

    final secretBox = await algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );

    final macBytes = secretBox.mac.bytes;

    final result =
        Uint8List(nonce.length + secretBox.cipherText.length + macBytes.length);
    result.setAll(0, nonce);
    result.setAll(nonce.length, secretBox.cipherText);
    result.setAll(nonce.length + secretBox.cipherText.length, macBytes);

    return result;
  }

  /// Decrypt ciphertext using XChaCha20-Poly1305.
  Future<Uint8List> decrypt({
    required Uint8List ciphertext,
    required Uint8List key,
  }) async {
    final algorithm = Xchacha20.poly1305Aead();
    final secretKey = SecretKey(key);

    // Extract nonce (24 bytes for XChaCha20), cipherText, and MAC (16 bytes for Poly1305)
    if (ciphertext.length < 24 + 16) {
      throw Exception('Ciphertext too short');
    }

    final nonce = ciphertext.sublist(0, 24);
    final coreCipherText = ciphertext.sublist(24, ciphertext.length - 16);
    final macBytes = ciphertext.sublist(ciphertext.length - 16);

    final secretBox = SecretBox(
      coreCipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    try {
      final plaintext = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      return Uint8List.fromList(plaintext);
    } catch (e) {
      throw Exception('Decryption failed (authentication/integrity error)');
    }
  }

  /// Encrypt a file (reads into memory for now, chunking left as future optimization).
  Future<void> encryptFile({
    required String inputPath,
    required String outputPath,
    required Uint8List key,
  }) async {
    final inputFile = File(inputPath);
    final outputFile = File(outputPath);
    final bytes = await inputFile.readAsBytes();

    final encryptedBytes = await encrypt(plaintext: bytes, key: key);
    await outputFile.writeAsBytes(encryptedBytes);
  }

  /// Decrypt a file (reads into memory for now, chunking left as future optimization).
  Future<void> decryptFile({
    required String inputPath,
    required String outputPath,
    required Uint8List key,
  }) async {
    final inputFile = File(inputPath);
    final outputFile = File(outputPath);
    final bytes = await inputFile.readAsBytes();

    final decryptedBytes = await decrypt(ciphertext: bytes, key: key);
    await outputFile.writeAsBytes(decryptedBytes);
  }

  // --- Asymmetric / Sharing Utils ---

  /// Generate a new X25519 key pair for the user.
  Future<SimpleKeyPair> generateKeyPair() async {
    final algorithm = X25519();
    return await algorithm.newKeyPair();
  }

  /// Derive a shared secret between our private key and their public key.
  Future<Uint8List> deriveSharedSecret({
    required SimpleKeyPair myKeyPair,
    required Uint8List theirPublicKeyBytes,
  }) async {
    final algorithm = X25519();
    final theirPublicKey = SimplePublicKey(
      theirPublicKeyBytes,
      type: KeyPairType.x25519,
    );

    final sharedSecretKey = await algorithm.sharedSecretKey(
      keyPair: myKeyPair,
      remotePublicKey: theirPublicKey,
    );

    final bytes = await sharedSecretKey.extractBytes();
    return Uint8List.fromList(bytes);
  }

  /// Reconstruct a key pair from a stored private key.
  Future<SimpleKeyPair> getKeyPairFromPrivateKey(
      Uint8List privateKeyBytes) async {
    final algorithm = X25519();
    return await algorithm.newKeyPairFromSeed(privateKeyBytes);
  }
}
