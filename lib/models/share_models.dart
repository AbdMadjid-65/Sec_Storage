import 'package:pri_vault/models/file_metadata.dart';

class Share {
  final String id;
  final String ownerId;
  final String? fileId;
  final String? folderId;
  final String type; // 'link', 'user', 'tresor'
  final String? passwordHash;
  final String? encryptedKey;
  final String permission;
  final int maxDownloads;
  final int downloadCount;
  final DateTime? expiresAt;
  final bool isRevoked;
  final DateTime? createdAt;

  const Share({
    required this.id,
    required this.ownerId,
    this.fileId,
    this.folderId,
    required this.type,
    this.passwordHash,
    this.encryptedKey,
    this.permission = 'view',
    this.maxDownloads = 0,
    this.downloadCount = 0,
    this.expiresAt,
    this.isRevoked = false,
    this.createdAt,
  });

  factory Share.fromJson(Map<String, dynamic> json) {
    return Share(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      fileId: json['file_id'] as String?,
      folderId: json['folder_id'] as String?,
      type: json['type'] as String,
      passwordHash: json['password_hash'] as String?,
      encryptedKey: json['encrypted_key'] as String?,
      permission: json['permission'] as String? ?? 'view',
      maxDownloads: (json['max_downloads'] as num?)?.toInt() ?? 0,
      downloadCount: (json['download_count'] as num?)?.toInt() ?? 0,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isRevoked: json['is_revoked'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'file_id': fileId,
      'folder_id': folderId,
      'type': type,
      'password_hash': passwordHash,
      'encrypted_key': encryptedKey,
      'permission': permission,
      'max_downloads': maxDownloads,
      'download_count': downloadCount,
      'expires_at': expiresAt?.toIso8601String(),
      'is_revoked': isRevoked,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class ShareRecipient {
  final String id;
  final String shareId;
  final String recipientId;
  final String? encryptedKey;
  final DateTime? createdAt;

  const ShareRecipient({
    required this.id,
    required this.shareId,
    required this.recipientId,
    this.encryptedKey,
    this.createdAt,
  });

  factory ShareRecipient.fromJson(Map<String, dynamic> json) {
    return ShareRecipient(
      id: json['id'] as String,
      shareId: json['share_id'] as String,
      recipientId: json['recipient_id'] as String,
      encryptedKey: json['encrypted_key'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'share_id': shareId,
      'recipient_id': recipientId,
      'encrypted_key': encryptedKey,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class SharedFile {
  final FileMetadata file;
  final ShareRecipient recipientShare;
  final Share parentShare;

  const SharedFile({
    required this.file,
    required this.recipientShare,
    required this.parentShare,
  });
}
