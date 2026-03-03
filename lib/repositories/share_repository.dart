// ============================================================
// PriVault – Share Repository (HTTP API)
// ============================================================

import 'dart:typed_data';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/models/file_metadata.dart';
import 'package:pri_vault/models/share_models.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';
import 'package:pri_vault/core/encryption/encryption_service.dart';

class ShareRepository {
  final ApiClient _api;
  final EncryptionService _encryptionService;

  ShareRepository(this._api, this._encryptionService);

  /// Create a public link with TTL (BR-13, BR-14).
  Future<(Share, String)> createPublicLink({
    required FileMetadata file,
    required Uint8List masterKey,
    DateTime? expiresAt,
    int maxDownloads = 0,
    String permission = 'view',
  }) async {
    if (file.fileKeyEncrypted == null) throw Exception('File key missing');

    // Decrypt file key
    final encryptedFileKeyBytes = CryptoUtils.fromBase64(file.fileKeyEncrypted!);
    final fileKey = await _encryptionService.decrypt(
      ciphertext: encryptedFileKeyBytes,
      key: masterKey,
    );

    // Generate link key (stays in URL hash, never sent to server)
    final linkKeyBytes = CryptoUtils.generateKey();
    final linkKeyString = CryptoUtils.toBase64(linkKeyBytes);

    // Encrypt file key with link key
    final newEncryptedKeyBytes = await _encryptionService.encrypt(
      plaintext: fileKey,
      key: linkKeyBytes,
    );
    final newEncryptedKeyBase64 = CryptoUtils.toBase64(newEncryptedKeyBytes);

    final response = await _api.post('/shares/link', body: {
      'file_id': file.id,
      'encrypted_key': newEncryptedKeyBase64,
      'permission': permission,
      'expires_at': expiresAt?.toIso8601String(),
      'max_downloads': maxDownloads,
    });

    return (Share.fromJson(response), linkKeyString);
  }

  /// Share with a specific user via email (BR-13).
  Future<void> shareWithUser({
    required FileMetadata file,
    required Uint8List masterKey,
    required Uint8List senderPrivateKey,
    required String recipientEmail,
    String permission = 'view',
    DateTime? expiresAt,
  }) async {
    if (file.fileKeyEncrypted == null) throw Exception('File key missing');

    // Decrypt file key
    final encryptedFileKeyBytes = CryptoUtils.fromBase64(file.fileKeyEncrypted!);
    final fileKey = await _encryptionService.decrypt(
      ciphertext: encryptedFileKeyBytes,
      key: masterKey,
    );

    // For email sharing, we encrypt the file key for the recipient
    // In a full implementation, we'd fetch recipient's public key and do DH
    final recipientEncryptedKey = CryptoUtils.toBase64(
      await _encryptionService.encrypt(plaintext: fileKey, key: masterKey),
    );

    await _api.post('/shares/email', body: {
      'file_id': file.id,
      'recipient_email': recipientEmail,
      'encrypted_key': recipientEncryptedKey,
      'recipient_encrypted_key': recipientEncryptedKey,
      'permission': permission,
      'expires_at': expiresAt?.toIso8601String(),
    });
  }

  /// Share with a team (BR-13).
  Future<void> shareWithTeam({
    required String fileId,
    required String teamId,
    String? encryptedKey,
    String permission = 'view',
    DateTime? expiresAt,
  }) async {
    await _api.post('/shares/team', body: {
      'file_id': fileId,
      'team_id': teamId,
      'encrypted_key': encryptedKey,
      'permission': permission,
      'expires_at': expiresAt?.toIso8601String(),
    });
  }

  /// Get shares for a file.
  Future<List<Share>> getSharesForFile(String fileId) async {
    final response = await _api.getList('/shares/mine');
    return (response)
        .map((e) => Share.fromJson(e as Map<String, dynamic>))
        .where((s) => s.fileId == fileId && !s.isRevoked)
        .toList();
  }

  /// Get all shares owned by current user.
  Future<List<Share>> getOwnerShares() async {
    final response = await _api.getList('/shares/mine');
    return response.map((e) => Share.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get files shared with current user.
  Future<List<SharedFile>> getSharedWithMe() async {
    final response = await _api.getList('/shares/with-me');
    return response.map((item) {
      final map = item as Map<String, dynamic>;
      return SharedFile(
        file: FileMetadata.fromJson(map),
        recipientShare: ShareRecipient(
          id: map['id']?.toString() ?? '',
          shareId: map['id']?.toString() ?? '',
          recipientId: '',
          encryptedKey: map['recipient_key'] as String?,
        ),
        parentShare: Share.fromJson(map),
      );
    }).toList();
  }

  /// Revoke a share (BR-15).
  Future<void> revokeShare(String shareId) async {
    await _api.delete('/shares/$shareId');
  }

  /// Update share permissions (BR-14).
  Future<void> updatePermissions(String shareId, {String? permission, DateTime? expiresAt}) async {
    await _api.put('/shares/$shareId/permissions', body: {
      if (permission != null) 'permission': permission,
      if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
    });
  }
}
