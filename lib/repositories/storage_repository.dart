// ============================================================
// PriVault – Storage Repository (Firebase)
// ============================================================

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:pri_vault/services/cloudinary_service.dart';
import 'package:pri_vault/models/file_metadata.dart';
import 'package:pri_vault/models/folder.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';
import 'package:pri_vault/core/encryption/encryption_service.dart';
import 'package:uuid/uuid.dart';

class StorageRepository {
  final FirebaseFirestore _firestore;
  final EncryptionService _encryptionService;

  StorageRepository(this._firestore, this._encryptionService);

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  DocumentReference get _userDoc => _firestore.collection('users').doc(_uid);

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

  // --- Folder Operations ---

  Future<List<Folder>> getFolders({String? parentId}) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('folders')
        .where('userId', isEqualTo: _uid);
    if (parentId != null) {
      query = query.where('parentId', isEqualTo: parentId);
    } else {
      query = query.where('parentId', isNull: true);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      try {
        final data = Map<String, dynamic>.from(doc.data());
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data['updatedAt'] is Timestamp) {
          data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
        }
        data['id'] = doc.id;
        data['userId'] ??= _uid;
        data['name'] ??= 'Untitled Folder';
        return Folder.fromJson(data);
      } catch (e) {
        debugPrint('Error parsing folder ${doc.id}: $e');
        return null;
      }
    }).whereType<Folder>().toList();
  }

  Future<Folder> createFolder({required String name, String? parentId, String? color}) async {
    final docRef = _firestore.collection('folders').doc();
    final data = {
      'userId': _uid,
      'name': name,
      'parentId': parentId,
      'color': color,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(data);
    return Folder(
      id: docRef.id,
      userId: _uid,
      name: name,
      parentId: parentId,
      color: color,
      createdAt: DateTime.now(),
    );
  }

  Future<void> renameFolder({required String folderId, required String newName}) async {
    await _firestore.collection('folders').doc(folderId).update({
      'name': newName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteFolder(String folderId) async {
    await _firestore.collection('folders').doc(folderId).delete();
  }

  Future<Folder?> getFolderById(String folderId) async {
    final doc = await _firestore.collection('folders').doc(folderId).get();
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    if (data['createdAt'] is Timestamp) {
      data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    if (data['updatedAt'] is Timestamp) {
      data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
    }
    data['id'] = doc.id;
    data['userId'] ??= _uid;
    data['name'] ??= 'Untitled Folder';
    return Folder.fromJson(data);
  }

  Future<List<Folder>> getFolderPath(String? folderId) async {
    if (folderId == null) return [];
    final path = <Folder>[];
    String? current = folderId;
    while (current != null) {
      final folder = await getFolderById(current);
      if (folder == null) break;
      path.add(folder);
      current = folder.parentId;
    }
    return path.reversed.toList();
  }

  // --- File Operations ---

  Future<List<FileMetadata>> getFiles({String? folderId, bool isVault = false}) async {
    Query<Map<String, dynamic>> query = _userDoc.collection('files')
        .where('isDeleted', isEqualTo: false);

    if (isVault) {
      query = query.where('isVaultFile', isEqualTo: true);
    }

    if (folderId != null) {
      query = query.where('folderId', isEqualTo: folderId);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      try {
        final data = Map<String, dynamic>.from(doc.data());
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data['updatedAt'] is Timestamp) {
          data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data['deletedAt'] is Timestamp) {
          data['deletedAt'] = (data['deletedAt'] as Timestamp).toDate().toIso8601String();
        }
        data['id'] = doc.id;
        data['userId'] ??= _uid;
        data['encryptedName'] ??= data['name'] ?? '';
        data['name'] ??= data['encryptedName'] ?? '';
        data['cloudinaryUrl'] ??= '';
        data['mimeType'] ??= 'application/octet-stream';
        data['sizeBytes'] ??= 0;
        data['isDeleted'] ??= false;
        data['isFavorite'] ??= false;
        data['isVaultFile'] ??= false;
        return FileMetadata.fromJson(data);
      } catch (e) {
        debugPrint('Error parsing file ${doc.id}: $e');
        return null;
      }
    }).whereType<FileMetadata>().toList();
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
    final fileId = const Uuid().v4();

    // 0. Quota check (BR-04/06)
    final userDoc = await _userDoc.get();
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};
    final usedBytes = (userData['storageUsedBytes'] ?? userData['storage_used_bytes'] ?? 0) as int;
    final maxBytes = (userData['storageMaxBytes'] ?? userData['storage_max_bytes'] ?? 3221225472) as int;
    final plaintext = await file.readAsBytes();
    final originalSize = plaintext.length;
    if (usedBytes + originalSize > maxBytes) {
      throw Exception(
        'Storage quota exceeded. You have used ${(usedBytes / (1024 * 1024)).toStringAsFixed(1)} MB '
        'of ${(maxBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB. '
        'Upgrade your plan for more storage.',
      );
    }

    // 1. Generate per-file key
    final fileKey = CryptoUtils.generateKey();
    progress?.value = 0.15;

    final fileNonce = CryptoUtils.generateNonce(24);
    final fileSalt = CryptoUtils.generateNonce(16);
    final sealedContent = await _encryptionService.encryptWithMetadata(
      plaintext: plaintext,
      key: fileKey,
      nonce: fileNonce,
    );
    progress?.value = 0.35;

    // 3. Detect real MIME type from file extension
    final fileName = file.path.split(Platform.pathSeparator).last;
    final detectedMimeType = lookupMimeType(fileName) ?? 'application/octet-stream';

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

    // 5. Upload ciphertext to Cloudinary
    final storagePath = 'users/$_uid/files/$fileId';
    final secureUrl = await CloudinaryService.uploadFile(
      Uint8List.fromList(sealedContent.packed),
      storagePath,
    );
    progress?.value = 0.85;

    // 6. Write metadata to Firestore
    final metadata = {
      'name': CryptoUtils.toBase64(encryptedName),
      'encryptedName': CryptoUtils.toBase64(encryptedName),
      'mimeType': detectedMimeType,
      'sizeBytes': originalSize,
      'cloudinaryUrl': secureUrl,
      'fileKeyEncrypted': CryptoUtils.toBase64(encryptedFileKey),
      'folderId': folderId,
      'isDeleted': false,
      'deletedAt': null,
      'isFavorite': false,
      'isVaultFile': isVaultFile,
      'version': 1,
      'encryptionNonce': CryptoUtils.toBase64(sealedContent.nonce),
      'encryptionSalt': CryptoUtils.toBase64(fileSalt),
      'encryptionMac': CryptoUtils.toBase64(sealedContent.mac),
      'encryptionAlgo': 'xchacha20-poly1305',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _userDoc.collection('files').doc(fileId).set(metadata);

    // 7. Update storage used (BR-06)
    await _updateStorageUsed(originalSize);

    progress?.value = 1.0;

    return FileMetadata(
      id: fileId,
      userId: _uid,
      name: metadata['name'] as String,
      encryptedName: metadata['encryptedName'] as String,
      mimeType: metadata['mimeType'] as String,
      sizeBytes: originalSize,
      cloudinaryUrl: secureUrl,
      fileKeyEncrypted: CryptoUtils.toBase64(encryptedFileKey),
      folderId: folderId,
      isDeleted: false,
      isFavorite: false,
      version: 1,
      encryptionIv: CryptoUtils.toBase64(sealedContent.nonce),
      createdAt: DateTime.now(),
    );
  }

  /// Download and decrypt a file.
  Future<Uint8List> downloadFile(FileMetadata metadata, Uint8List fileKey) async {
    // 1. Download ciphertext from Cloudinary
    final response = await http.get(Uri.parse(metadata.cloudinaryUrl));
    if (response.statusCode != 200) throw Exception('File not found in storage');
    final data = response.bodyBytes;

    // 2. Decrypt file content using per-file key
    Uint8List? expectedNonce;
    if (metadata.encryptionIv != null && metadata.encryptionIv!.isNotEmpty) {
      expectedNonce = CryptoUtils.fromBase64(metadata.encryptionIv!);
    }
    try {
      return _encryptionService.decryptWithMetadata(
        ciphertext: data,
        key: fileKey,
        expectedNonce: expectedNonce,
      );
    } catch (e) {
      debugPrint('[Storage] File decrypt failure fileId=${metadata.id} error=$e');
      rethrow;
    }
  }

  // --- Soft Delete / Trash ---

  Future<void> deleteFile(FileMetadata metadata) async {
    await _userDoc.collection('files').doc(metadata.id).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<FileMetadata>> getDeletedFiles() async {
    final snapshot = await _userDoc.collection('files')
        .where('isDeleted', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) {
      try {
        final data = Map<String, dynamic>.from(doc.data());
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data['updatedAt'] is Timestamp) {
          data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data['deletedAt'] is Timestamp) {
          data['deletedAt'] = (data['deletedAt'] as Timestamp).toDate().toIso8601String();
        }
        data['id'] = doc.id;
        data['userId'] ??= _uid;
        data['encryptedName'] ??= data['name'] ?? '';
        data['name'] ??= data['encryptedName'] ?? '';
        data['cloudinaryUrl'] ??= '';
        data['mimeType'] ??= 'application/octet-stream';
        data['sizeBytes'] ??= 0;
        data['isDeleted'] ??= false;
        data['isFavorite'] ??= false;
        data['isVaultFile'] ??= false;
        return FileMetadata.fromJson(data);
      } catch (e) {
        debugPrint('Error parsing file ${doc.id}: $e');
        return null;
      }
    }).whereType<FileMetadata>().toList();
  }

  Future<void> restoreFile(FileMetadata metadata) async {
    await _userDoc.collection('files').doc(metadata.id).update({
      'isDeleted': false,
      'deletedAt': null,
    });
  }

  Future<void> permanentlyDeleteFile(FileMetadata metadata) async {
    // Delete from Cloudinary
    try {
      final storagePath = 'users/$_uid/files/${metadata.id}';
      await CloudinaryService.deleteFile(storagePath);
    } catch (_) {}

    // Delete from Firestore
    await _userDoc.collection('files').doc(metadata.id).delete();

    // Update storage usage
    await _updateStorageUsed(-metadata.sizeBytes);
  }

  // --- Favorites ---

  Future<void> toggleFavorite(FileMetadata metadata) async {
    await _userDoc.collection('files').doc(metadata.id).update({
      'isFavorite': !metadata.isFavorite,
    });
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

  /// Update the user's storage used counter.
  Future<void> _updateStorageUsed(int deltaBytes) async {
    await _userDoc.update({
      'storageUsedBytes': FieldValue.increment(deltaBytes),
    });
  }

}
