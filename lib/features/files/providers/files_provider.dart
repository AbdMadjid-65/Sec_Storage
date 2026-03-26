// ============================================================
// PriVault – Files & Folders Providers (Riverpod + Firebase)
// ============================================================
// Provides storage repository, encryption, folder/file data,
// and the currentFoldersProvider/currentFilesProvider used by
// FilesScreen.
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/core/encryption/encryption_service.dart';
import 'package:pri_vault/repositories/storage_repository.dart';
import 'package:pri_vault/models/file_metadata.dart';
import 'package:pri_vault/models/folder.dart';
import 'package:pri_vault/services/storage_service.dart';
import 'package:pri_vault/services/audit_service.dart';
import 'package:pri_vault/services/notification_service.dart';

/// Storage Repository provider.
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final encryption = ref.watch(encryptionServiceProvider);
  
  return StorageRepository(firestore, encryption);
});

/// Storage Service provider.
final storageServiceProvider = Provider<StorageService>((ref) {
  final firestore = ref.read(firestoreProvider);
  return StorageService(firestore);
});

/// Audit Service provider (BR-16/17).
final auditServiceProvider = Provider<AuditService>((ref) {
  final firestore = ref.read(firestoreProvider);
  return AuditService(firestore);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.read(firestoreProvider));
});

/// Encryption service provider.
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});

/// Folders for a given parent.
final foldersProvider = FutureProvider.family<List<Folder>, String?>((ref, parentId) async {
  final repo = ref.read(storageRepositoryProvider);
  return repo.getFolders(parentId: parentId);
});

/// Files for a given folder.
final filesProvider = FutureProvider.family<List<FileMetadata>, String?>((ref, folderId) async {
  final repo = ref.read(storageRepositoryProvider);
  return repo.getFiles(folderId: folderId);
});

/// currentFoldersProvider — alias used by FilesScreen for current folder view.
final currentFoldersProvider = FutureProvider.family<List<Folder>, String?>((ref, folderId) async {
  final repo = ref.read(storageRepositoryProvider);
  return repo.getFolders(parentId: folderId);
});

/// currentFilesProvider — alias used by FilesScreen for current folder files.
final currentFilesProvider = FutureProvider.family<List<FileMetadata>, String?>((ref, folderId) async {
  final repo = ref.read(storageRepositoryProvider);
  return repo.getFiles(folderId: folderId);
});

final folderPathProvider = FutureProvider.family<List<Folder>, String?>((ref, folderId) async {
  final repo = ref.read(storageRepositoryProvider);
  return repo.getFolderPath(folderId);
});

/// Deleted files (trash).
final deletedFilesProvider = FutureProvider<List<FileMetadata>>((ref) async {
  final repo = ref.read(storageRepositoryProvider);
  return repo.getDeletedFiles();
});

/// Storage usage.
final storageUsageProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(storageServiceProvider);
  return service.getUsage();
});
