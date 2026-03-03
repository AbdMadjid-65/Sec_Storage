// ============================================================
// PriVault – Storage Repository (HTTP API)
// ============================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/models/file_metadata.dart';
import 'package:pri_vault/models/folder.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';
import 'package:pri_vault/core/encryption/encryption_service.dart';

class StorageRepository {
  // uploadFileWithProgress delegates to uploadFile (used by FilesScreen)
  Future<FileMetadata> uploadFileWithProgress({
    required File file,
    required Uint8List masterKey,
    String? folderId,
    ValueNotifier<double>? progress,
    bool isVaultFile = false,
  }) async {
    return uploadFile(
      file: file,
      masterKey: masterKey,
      folderId: folderId,
      isVaultFile: isVaultFile,
      progress: progress,
    );
  }

  final ApiClient _api;
  final EncryptionService _encryptionService;

  StorageRepository(this._api, this._encryptionService);

  // --- Folder Operations ---

  Future<List<Folder>> getFolders({String? parentId}) async {
    final path = parentId != null
        ? '/folders?parent_id=$parentId'
        : '/folders';
    final response = await _api.getList(path);
    return response.map((f) => Folder.fromJson(f as Map<String, dynamic>)).toList();
  }

  Future<Folder> createFolder({required String name, String? parentId}) async {
    final response = await _api.post('/folders', body: {
      'name': name,
      'parent_id': parentId,
    });
    return Folder.fromJson(response);
  }

  Future<void> renameFolder({required String folderId, required String newName}) async {
    await _api.put('/folders/$folderId', body: {'name': newName});
  }

  Future<void> deleteFolder(String folderId) async {
    await _api.delete('/folders/$folderId');
  }

  // --- File Operations ---

  Future<List<FileMetadata>> getFiles({String? folderId, bool isVault = false}) async {
    String path = '/files?is_vault=$isVault';
    if (folderId != null) path += '&folder_id=$folderId';
    final response = await _api.getList(path);
    return response.map((f) => FileMetadata.fromJson(f as Map<String, dynamic>)).toList();
  }

  /// Upload an encrypted file.
  Future<FileMetadata> uploadFile({
    required File file,
    required Uint8List masterKey,
    String? folderId,
    bool isVaultFile = false,
    ValueNotifier<double>? progress,
  }) async {
    progress?.value = 0.05;

    // 1. Generate per-file key
    final fileKey = CryptoUtils.generateKey();

    // 2. Encrypt file content (client-side, BR-10)
    final plaintext = await file.readAsBytes();
    final originalSize = plaintext.length;
    progress?.value = 0.15;

    final ciphertext = await _encryptionService.encrypt(
      plaintext: plaintext,
      key: fileKey,
    );
    progress?.value = 0.35;

    // 3. Encrypt file name
    final fileName = file.path.split(Platform.pathSeparator).last;
    final encryptedName = await _encryptionService.encrypt(
      plaintext: Uint8List.fromList(fileName.codeUnits),
      key: masterKey,
    );

    // 4. Encrypt file key with master key
    final encryptedFileKey = await _encryptionService.encrypt(
      plaintext: fileKey,
      key: masterKey,
    );
    progress?.value = 0.45;

    // 5. Write ciphertext to a temp file for upload
    final tempDir = await Directory.systemTemp.createTemp('privault_');
    final tempFile = File('${tempDir.path}/encrypted_upload');
    await tempFile.writeAsBytes(ciphertext);

    // 6. Upload via API
    final response = await _api.uploadFile(
      path: '/files/upload',
      file: tempFile,
      fields: {
        'encrypted_name': CryptoUtils.toBase64(encryptedName),
        'file_key_encrypted': CryptoUtils.toBase64(encryptedFileKey),
        'original_size': originalSize.toString(),
        if (folderId != null) 'folder_id': folderId,
        'is_vault_file': isVaultFile.toString(),
      },
    );
    progress?.value = 0.95;

    // Clean up temp file
    try { await tempFile.delete(); await tempDir.delete(); } catch (_) {}

    progress?.value = 1.0;
    return FileMetadata.fromJson(response);
  }

  /// Download and decrypt a file.
  Future<Uint8List> downloadFile(FileMetadata metadata, Uint8List masterKey) async {
    // 1. Download ciphertext
    final ciphertext = await _api.downloadFile('/files/${metadata.id}/download');

    // 2. Decrypt file key
    if (metadata.fileKeyEncrypted == null) throw Exception('File key missing');
    final encryptedFileKey = CryptoUtils.fromBase64(metadata.fileKeyEncrypted!);
    final fileKey = await _encryptionService.decrypt(
      ciphertext: encryptedFileKey,
      key: masterKey,
    );

    // 3. Decrypt file content
    return await _encryptionService.decrypt(
      ciphertext: ciphertext,
      key: fileKey,
    );
  }

  // --- Soft Delete / Trash ---

  Future<void> deleteFile(FileMetadata metadata) async {
    await _api.delete('/files/${metadata.id}');
  }

  Future<List<FileMetadata>> getDeletedFiles() async {
    final response = await _api.getList('/files/trash/list');
    return response.map((f) => FileMetadata.fromJson(f as Map<String, dynamic>)).toList();
  }

  Future<void> restoreFile(FileMetadata metadata) async {
    await _api.put('/files/${metadata.id}/restore');
  }

  Future<void> permanentlyDeleteFile(FileMetadata metadata) async {
    await _api.delete('/files/${metadata.id}/permanent');
  }

  // --- Favorites ---

  Future<void> toggleFavorite(FileMetadata metadata) async {
    await _api.post('/files/${metadata.id}/favorite');
  }

  // --- Helpers ---

  Future<String> decryptFileName(FileMetadata metadata, Uint8List masterKey) async {
    if (metadata.encryptedName.isEmpty) return 'Untitled File';
    try {
      final decryptedBytes = await _encryptionService.decrypt(
        ciphertext: CryptoUtils.fromBase64(metadata.encryptedName),
        key: masterKey,
      );
      return String.fromCharCodes(decryptedBytes);
    } catch (_) {
      return 'Encrypted File';
    }
  }
}
