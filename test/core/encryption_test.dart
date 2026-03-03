import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pri_vault/core/encryption/key_derivation.dart';

import 'package:pri_vault/core/encryption/encryption_service.dart';

void main() {
  group('KeyDerivation', () {
    test('deriveMasterKey returns consistent 32-byte key for same inputs',
        () async {
      final salt = Uint8List.fromList(List.generate(16, (i) => i));
      // Use low memory/iterations parameters for fast unit testing
      final key1 = await KeyDerivation.deriveMasterKey(
        password: 'test_password',
        salt: salt,
        memoryKB: 4096,
        parallelism: 1,
        iterations: 1,
      );
      final key2 = await KeyDerivation.deriveMasterKey(
        password: 'test_password',
        salt: salt,
        memoryKB: 4096,
        parallelism: 1,
        iterations: 1,
      );

      expect(key1.length, 32);
      expect(key1, equals(key2));
    });

    test('deriveSubKey returns distinct keys for different info', () async {
      final masterKey = Uint8List.fromList(List.generate(32, (i) => i));
      final subKey1 = await KeyDerivation.deriveSubKey(
        masterKey: masterKey,
        info: 'file_storage',
      );
      final subKey2 = await KeyDerivation.deriveSubKey(
        masterKey: masterKey,
        info: 'chat',
      );

      expect(subKey1.length, 32);
      expect(subKey2.length, 32);
      expect(subKey1, isNot(equals(subKey2)));
    });
  });

  group('EncryptionService', () {
    late EncryptionService service;
    late Uint8List testKey;

    setUp(() {
      service = EncryptionService();
      testKey = Uint8List.fromList(List.generate(32, (i) => i));
    });

    test('Encrypt and Decrypt cycle works', () async {
      final plaintext = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final ciphertext =
          await service.encrypt(plaintext: plaintext, key: testKey);

      expect(ciphertext.length, greaterThan(plaintext.length));

      final decrypted =
          await service.decrypt(ciphertext: ciphertext, key: testKey);
      expect(decrypted, equals(plaintext));
    });

    test('Decrypting with wrong key fails', () async {
      final plaintext = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final ciphertext =
          await service.encrypt(plaintext: plaintext, key: testKey);

      final wrongKey = Uint8List.fromList(List.generate(32, (i) => i + 1));

      expect(
        () => service.decrypt(ciphertext: ciphertext, key: wrongKey),
        throwsException,
      );
    });

    test('File encryption works', () async {
      final tempDir = Directory.systemTemp.createTempSync('privault_test');
      final inFile = File('${tempDir.path}/in.txt');
      final encFile = File('${tempDir.path}/enc.bin');
      final outFile = File('${tempDir.path}/out.txt');

      await inFile.writeAsString('Hello Secret World!');

      await service.encryptFile(
        inputPath: inFile.path,
        outputPath: encFile.path,
        key: testKey,
      );
      await service.decryptFile(
        inputPath: encFile.path,
        outputPath: outFile.path,
        key: testKey,
      );

      final outText = await outFile.readAsString();
      expect(outText, 'Hello Secret World!');

      tempDir.deleteSync(recursive: true);
    });
  });
}
