// ============================================================
// PriVault – Share Models
// ============================================================

import 'package:pri_vault/models/file_metadata.dart';

class Share {
  final String id;
  final String ownerId;
  final String? fileId;
  final String? folderId;
  final String type; // 'link', 'user', 'team'
  final String? passwordHash;
  final String? encryptedKey;
  final String permission; // 'view', 'download'
  final int maxDownloads;
  final int downloadCount;
  final DateTime? expiresAt;
  final bool isRevoked;
  final DateTime? createdAt;
  // User share
  final String? sharedWithEmail;
  // Team share
  final String? teamId;
  final String? senderPublicKey;

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
    this.sharedWithEmail,
    this.teamId,
    this.senderPublicKey,
  });

  factory Share.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

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
      expiresAt: parseDate(json['expires_at']),
      isRevoked: json['is_revoked'] as bool? ?? false,
      createdAt: parseDate(json['created_at']),
      sharedWithEmail: json['shared_with_email'] as String?,
      teamId: json['team_id'] as String?,
      senderPublicKey: json['sender_public_key'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
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
        'shared_with_email': sharedWithEmail,
        'team_id': teamId,
        'sender_public_key': senderPublicKey,
      };

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isActive => !isRevoked && !isExpired;

  String get displayType {
    switch (type) {
      case 'link': return 'Link';
      case 'user': return 'User';
      case 'team': return 'Team';
      default: return type;
    }
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

  factory ShareRecipient.fromJson(Map<String, dynamic> json) => ShareRecipient(
        id: json['id'] as String,
        shareId: json['share_id'] as String,
        recipientId: json['recipient_id'] as String,
        encryptedKey: json['encrypted_key'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'share_id': shareId,
        'recipient_id': recipientId,
        'encrypted_key': encryptedKey,
        'created_at': createdAt?.toIso8601String(),
      };
}

class SharedFile {
  final FileMetadata file;
  final ShareRecipient recipientShare;
  final Share parentShare;
  // Owner's display email fetched separately
  final String? ownerEmail;

  const SharedFile({
    required this.file,
    required this.recipientShare,
    required this.parentShare,
    this.ownerEmail,
  });
}