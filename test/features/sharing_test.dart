import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:cryptography/cryptography.dart';
import 'package:pri_vault/core/encryption/encryption_service.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';

void main() {
  late EncryptionService encryptionService;

  setUp(() {
    encryptionService = EncryptionService();
  });

  group('Sharing Encryption Loop Tests', () {
    test('Public Link Loop: End-to-End', () async {
      final fileKey = CryptoUtils.generateKey();
      final linkKey = CryptoUtils.generateKey();

      final encrypted = await encryptionService.encrypt(
        plaintext: fileKey,
        key: linkKey,
      );

      final decrypted = await encryptionService.decrypt(
        ciphertext: encrypted,
        key: linkKey,
      );

      expect(decrypted, equals(fileKey));
    });

    test('DH Loop: End-to-End Encryption', () async {
      final senderKeyPair = await encryptionService.generateKeyPair();
      final receiverKeyPair = await encryptionService.generateKeyPair();

      final receiverPubKey = await receiverKeyPair.extractPublicKey();
      final senderSecret = await encryptionService.deriveSharedSecret(
        myKeyPair: senderKeyPair,
        theirPublicKeyBytes: Uint8List.fromList(receiverPubKey.bytes),
      );

      final senderPubKey = await senderKeyPair.extractPublicKey();
      final receiverSecret = await encryptionService.deriveSharedSecret(
        myKeyPair: receiverKeyPair,
        theirPublicKeyBytes: Uint8List.fromList(senderPubKey.bytes),
      );

      expect(senderSecret, equals(receiverSecret));

      final fileKey = CryptoUtils.generateKey();
      final encrypted = await encryptionService.encrypt(
        plaintext: fileKey,
        key: senderSecret,
      );

      final decrypted = await encryptionService.decrypt(
        ciphertext: encrypted,
        key: receiverSecret,
      );

      expect(decrypted, equals(fileKey));
    });
  });
}
