// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FileMetadataImpl _$$FileMetadataImplFromJson(Map<String, dynamic> json) =>
    _$FileMetadataImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      folderId: json['folderId'] as String?,
      name: json['name'] as String,
      encryptedName: json['encryptedName'] as String,
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      storagePath: json['storagePath'] as String,
      thumbnailPath: json['thumbnailPath'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      version: (json['version'] as num?)?.toInt() ?? 1,
      encryptionIv: json['encryptionIv'] as String?,
      fileKeyEncrypted: json['fileKeyEncrypted'] as String?,
      checksum: json['checksum'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$FileMetadataImplToJson(_$FileMetadataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'folderId': instance.folderId,
      'name': instance.name,
      'encryptedName': instance.encryptedName,
      'mimeType': instance.mimeType,
      'sizeBytes': instance.sizeBytes,
      'storagePath': instance.storagePath,
      'thumbnailPath': instance.thumbnailPath,
      'isFavorite': instance.isFavorite,
      'isDeleted': instance.isDeleted,
      'deletedAt': instance.deletedAt?.toIso8601String(),
      'version': instance.version,
      'encryptionIv': instance.encryptionIv,
      'fileKeyEncrypted': instance.fileKeyEncrypted,
      'checksum': instance.checksum,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
