// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileImpl _$$ProfileImplFromJson(Map<String, dynamic> json) =>
    _$ProfileImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      plan: json['plan'] as String? ?? 'free',
      storageUsedBytes: (json['storageUsedBytes'] as num?)?.toInt() ?? 0,
      storageMaxBytes: (json['storageMaxBytes'] as num?)?.toInt() ?? 5368709120,
      publicKey: json['publicKey'] as String?,
      encryptedPrivateKey: json['encryptedPrivateKey'] as String?,
      salt: json['salt'] as String?,
      is2faEnabled: json['is2faEnabled'] as bool? ?? false,
      totpSecretEncrypted: json['totpSecretEncrypted'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ProfileImplToJson(_$ProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'plan': instance.plan,
      'storageUsedBytes': instance.storageUsedBytes,
      'storageMaxBytes': instance.storageMaxBytes,
      'publicKey': instance.publicKey,
      'encryptedPrivateKey': instance.encryptedPrivateKey,
      'salt': instance.salt,
      'is2faEnabled': instance.is2faEnabled,
      'totpSecretEncrypted': instance.totpSecretEncrypted,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
