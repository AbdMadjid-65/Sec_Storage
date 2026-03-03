// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ShareImpl _$$ShareImplFromJson(Map<String, dynamic> json) => _$ShareImpl(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      fileId: json['fileId'] as String?,
      folderId: json['folderId'] as String?,
      type: json['type'] as String,
      passwordHash: json['passwordHash'] as String?,
      encryptedKey: json['encryptedKey'] as String?,
      permission: json['permission'] as String? ?? 'view',
      maxDownloads: (json['maxDownloads'] as num?)?.toInt() ?? 0,
      downloadCount: (json['downloadCount'] as num?)?.toInt() ?? 0,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      isRevoked: json['isRevoked'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ShareImplToJson(_$ShareImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ownerId': instance.ownerId,
      'fileId': instance.fileId,
      'folderId': instance.folderId,
      'type': instance.type,
      'passwordHash': instance.passwordHash,
      'encryptedKey': instance.encryptedKey,
      'permission': instance.permission,
      'maxDownloads': instance.maxDownloads,
      'downloadCount': instance.downloadCount,
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'isRevoked': instance.isRevoked,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$ShareRecipientImpl _$$ShareRecipientImplFromJson(Map<String, dynamic> json) =>
    _$ShareRecipientImpl(
      id: json['id'] as String,
      shareId: json['shareId'] as String,
      recipientId: json['recipientId'] as String,
      encryptedKey: json['encryptedKey'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ShareRecipientImplToJson(
        _$ShareRecipientImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shareId': instance.shareId,
      'recipientId': instance.recipientId,
      'encryptedKey': instance.encryptedKey,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
