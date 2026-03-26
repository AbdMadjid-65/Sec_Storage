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
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart';
import 'package:pri_vault/core/encryption/key_derivation.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';

/// Encryption service for PriVault.
class EncryptionService {
  static const int _xchachaNonceLength = 24;
  static const int _poly1305MacLength = 16;

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
    final sealed = await encryptWithMetadata(plaintext: plaintext, key: key);
    return sealed.packed;
  }

  /// Decrypt ciphertext using XChaCha20-Poly1305.
  Future<Uint8List> decrypt({
    required Uint8List ciphertext,
    required Uint8List key,
  }) async {
    return decryptWithMetadata(ciphertext: ciphertext, key: key);
  }

  Future<SealedData> encryptWithMetadata({
    required Uint8List plaintext,
    required Uint8List key,
    Uint8List? nonce,
  }) async {
    final algorithm = Xchacha20.poly1305Aead();
    final secretKey = SecretKey(key);
    final usedNonce = nonce ?? CryptoUtils.generateNonce(_xchachaNonceLength);
    if (usedNonce.length != _xchachaNonceLength) {
      throw ArgumentError('Invalid nonce length: ${usedNonce.length}');
    }

    final secretBox = await algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: usedNonce,
    );

    final macBytes = Uint8List.fromList(secretBox.mac.bytes);
    final packed = Uint8List(
      usedNonce.length + secretBox.cipherText.length + macBytes.length,
    );
    packed.setAll(0, usedNonce);
    packed.setAll(usedNonce.length, secretBox.cipherText);
    packed.setAll(usedNonce.length + secretBox.cipherText.length, macBytes);

    return SealedData(
      packed: packed,
      nonce: Uint8List.fromList(usedNonce),
      mac: macBytes,
    );
  }

  Future<Uint8List> decryptWithMetadata({
    required Uint8List ciphertext,
    required Uint8List key,
    Uint8List? expectedNonce,
  }) async {
    final algorithm = Xchacha20.poly1305Aead();
    final secretKey = SecretKey(key);

    if (ciphertext.length < _xchachaNonceLength + _poly1305MacLength) {
      throw Exception('Ciphertext too short');
    }

    final nonce = ciphertext.sublist(0, _xchachaNonceLength);
    final coreCipherText = ciphertext.sublist(
      _xchachaNonceLength,
      ciphertext.length - _poly1305MacLength,
    );
    final macBytes = ciphertext.sublist(ciphertext.length - _poly1305MacLength);

    if (expectedNonce != null &&
        !CryptoUtils.constantTimeEquals(expectedNonce, nonce)) {
      debugPrint(
        '[Crypto] Wrong nonce. expected=${CryptoUtils.toBase64(expectedNonce)} '
        'actual=${CryptoUtils.toBase64(Uint8List.fromList(nonce))}',
      );
      throw Exception('Decryption failed: wrong nonce');
    }

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
      debugPrint(
        '[Crypto] Decryption failed. key_length=${key.length} '
        'ciphertext_length=${ciphertext.length} error=$e',
      );
      throw Exception(
        'Decryption failed (key mismatch, corrupted ciphertext, or wrong nonce)',
      );
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
      Uint8List privateKeyBytes,) async {
    final algorithm = X25519();
    return await algorithm.newKeyPairFromSeed(privateKeyBytes);
  }
}

class SealedData {
  final Uint8List packed;
  final Uint8List nonce;
  final Uint8List mac;

  const SealedData({
    required this.packed,
    required this.nonce,
    required this.mac,
  });
}
