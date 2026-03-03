// ============================================================
// PriVault – Share Model
// ============================================================

class ShareModel {
  final String id;
  final String ownerId;
  final String? fileId;
  final String? folderId;
  final String type; // 'link', 'user', 'tresor'
  final String? password; // Encrypted share password (if any)
  final String? encryptedKey; // Re-encrypted file key for recipient
  final String permission; // 'view', 'edit', 'admin'
  final int maxDownloads;
  final int downloadCount;
  final DateTime? expiresAt;
  final bool isRevoked;
  final DateTime createdAt;

  const ShareModel({
    required this.id,
    required this.ownerId,
    this.fileId,
    this.folderId,
    required this.type,
    this.password,
    this.encryptedKey,
    this.permission = 'view',
    this.maxDownloads = 0,
    this.downloadCount = 0,
    this.expiresAt,
    this.isRevoked = false,
    required this.createdAt,
  });

  factory ShareModel.fromJson(Map<String, dynamic> json) {
    return ShareModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      fileId: json['file_id'] as String?,
      folderId: json['folder_id'] as String?,
      type: json['type'] as String,
      password: json['password'] as String?,
      encryptedKey: json['encrypted_key'] as String?,
      permission: json['permission'] as String? ?? 'view',
      maxDownloads: json['max_downloads'] as int? ?? 0,
      downloadCount: json['download_count'] as int? ?? 0,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isRevoked: json['is_revoked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'file_id': fileId,
      'folder_id': folderId,
      'type': type,
      'password': password,
      'encrypted_key': encryptedKey,
      'permission': permission,
      'max_downloads': maxDownloads,
      'download_count': downloadCount,
      'expires_at': expiresAt?.toIso8601String(),
      'is_revoked': isRevoked,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
