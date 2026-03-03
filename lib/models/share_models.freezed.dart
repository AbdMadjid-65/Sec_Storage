// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'share_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Share _$ShareFromJson(Map<String, dynamic> json) {
  return _Share.fromJson(json);
}

/// @nodoc
mixin _$Share {
  String get id => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String? get fileId => throw _privateConstructorUsedError;
  String? get folderId => throw _privateConstructorUsedError;
  String get type =>
      throw _privateConstructorUsedError; // 'link', 'user', 'tresor'
  String? get passwordHash => throw _privateConstructorUsedError;
  String? get encryptedKey => throw _privateConstructorUsedError;
  String get permission => throw _privateConstructorUsedError;
  int get maxDownloads => throw _privateConstructorUsedError;
  int get downloadCount => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  bool get isRevoked => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ShareCopyWith<Share> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShareCopyWith<$Res> {
  factory $ShareCopyWith(Share value, $Res Function(Share) then) =
      _$ShareCopyWithImpl<$Res, Share>;
  @useResult
  $Res call(
      {String id,
      String ownerId,
      String? fileId,
      String? folderId,
      String type,
      String? passwordHash,
      String? encryptedKey,
      String permission,
      int maxDownloads,
      int downloadCount,
      DateTime? expiresAt,
      bool isRevoked,
      DateTime? createdAt});
}

/// @nodoc
class _$ShareCopyWithImpl<$Res, $Val extends Share>
    implements $ShareCopyWith<$Res> {
  _$ShareCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? fileId = freezed,
    Object? folderId = freezed,
    Object? type = null,
    Object? passwordHash = freezed,
    Object? encryptedKey = freezed,
    Object? permission = null,
    Object? maxDownloads = null,
    Object? downloadCount = null,
    Object? expiresAt = freezed,
    Object? isRevoked = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      fileId: freezed == fileId
          ? _value.fileId
          : fileId // ignore: cast_nullable_to_non_nullable
              as String?,
      folderId: freezed == folderId
          ? _value.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      passwordHash: freezed == passwordHash
          ? _value.passwordHash
          : passwordHash // ignore: cast_nullable_to_non_nullable
              as String?,
      encryptedKey: freezed == encryptedKey
          ? _value.encryptedKey
          : encryptedKey // ignore: cast_nullable_to_non_nullable
              as String?,
      permission: null == permission
          ? _value.permission
          : permission // ignore: cast_nullable_to_non_nullable
              as String,
      maxDownloads: null == maxDownloads
          ? _value.maxDownloads
          : maxDownloads // ignore: cast_nullable_to_non_nullable
              as int,
      downloadCount: null == downloadCount
          ? _value.downloadCount
          : downloadCount // ignore: cast_nullable_to_non_nullable
              as int,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isRevoked: null == isRevoked
          ? _value.isRevoked
          : isRevoked // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ShareImplCopyWith<$Res> implements $ShareCopyWith<$Res> {
  factory _$$ShareImplCopyWith(
          _$ShareImpl value, $Res Function(_$ShareImpl) then) =
      __$$ShareImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String ownerId,
      String? fileId,
      String? folderId,
      String type,
      String? passwordHash,
      String? encryptedKey,
      String permission,
      int maxDownloads,
      int downloadCount,
      DateTime? expiresAt,
      bool isRevoked,
      DateTime? createdAt});
}

/// @nodoc
class __$$ShareImplCopyWithImpl<$Res>
    extends _$ShareCopyWithImpl<$Res, _$ShareImpl>
    implements _$$ShareImplCopyWith<$Res> {
  __$$ShareImplCopyWithImpl(
      _$ShareImpl _value, $Res Function(_$ShareImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? fileId = freezed,
    Object? folderId = freezed,
    Object? type = null,
    Object? passwordHash = freezed,
    Object? encryptedKey = freezed,
    Object? permission = null,
    Object? maxDownloads = null,
    Object? downloadCount = null,
    Object? expiresAt = freezed,
    Object? isRevoked = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$ShareImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      fileId: freezed == fileId
          ? _value.fileId
          : fileId // ignore: cast_nullable_to_non_nullable
              as String?,
      folderId: freezed == folderId
          ? _value.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      passwordHash: freezed == passwordHash
          ? _value.passwordHash
          : passwordHash // ignore: cast_nullable_to_non_nullable
              as String?,
      encryptedKey: freezed == encryptedKey
          ? _value.encryptedKey
          : encryptedKey // ignore: cast_nullable_to_non_nullable
              as String?,
      permission: null == permission
          ? _value.permission
          : permission // ignore: cast_nullable_to_non_nullable
              as String,
      maxDownloads: null == maxDownloads
          ? _value.maxDownloads
          : maxDownloads // ignore: cast_nullable_to_non_nullable
              as int,
      downloadCount: null == downloadCount
          ? _value.downloadCount
          : downloadCount // ignore: cast_nullable_to_non_nullable
              as int,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isRevoked: null == isRevoked
          ? _value.isRevoked
          : isRevoked // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ShareImpl implements _Share {
  const _$ShareImpl(
      {required this.id,
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
      this.createdAt});

  factory _$ShareImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShareImplFromJson(json);

  @override
  final String id;
  @override
  final String ownerId;
  @override
  final String? fileId;
  @override
  final String? folderId;
  @override
  final String type;
// 'link', 'user', 'tresor'
  @override
  final String? passwordHash;
  @override
  final String? encryptedKey;
  @override
  @JsonKey()
  final String permission;
  @override
  @JsonKey()
  final int maxDownloads;
  @override
  @JsonKey()
  final int downloadCount;
  @override
  final DateTime? expiresAt;
  @override
  @JsonKey()
  final bool isRevoked;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Share(id: $id, ownerId: $ownerId, fileId: $fileId, folderId: $folderId, type: $type, passwordHash: $passwordHash, encryptedKey: $encryptedKey, permission: $permission, maxDownloads: $maxDownloads, downloadCount: $downloadCount, expiresAt: $expiresAt, isRevoked: $isRevoked, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShareImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.fileId, fileId) || other.fileId == fileId) &&
            (identical(other.folderId, folderId) ||
                other.folderId == folderId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.passwordHash, passwordHash) ||
                other.passwordHash == passwordHash) &&
            (identical(other.encryptedKey, encryptedKey) ||
                other.encryptedKey == encryptedKey) &&
            (identical(other.permission, permission) ||
                other.permission == permission) &&
            (identical(other.maxDownloads, maxDownloads) ||
                other.maxDownloads == maxDownloads) &&
            (identical(other.downloadCount, downloadCount) ||
                other.downloadCount == downloadCount) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.isRevoked, isRevoked) ||
                other.isRevoked == isRevoked) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      ownerId,
      fileId,
      folderId,
      type,
      passwordHash,
      encryptedKey,
      permission,
      maxDownloads,
      downloadCount,
      expiresAt,
      isRevoked,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ShareImplCopyWith<_$ShareImpl> get copyWith =>
      __$$ShareImplCopyWithImpl<_$ShareImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShareImplToJson(
      this,
    );
  }
}

abstract class _Share implements Share {
  const factory _Share(
      {required final String id,
      required final String ownerId,
      final String? fileId,
      final String? folderId,
      required final String type,
      final String? passwordHash,
      final String? encryptedKey,
      final String permission,
      final int maxDownloads,
      final int downloadCount,
      final DateTime? expiresAt,
      final bool isRevoked,
      final DateTime? createdAt}) = _$ShareImpl;

  factory _Share.fromJson(Map<String, dynamic> json) = _$ShareImpl.fromJson;

  @override
  String get id;
  @override
  String get ownerId;
  @override
  String? get fileId;
  @override
  String? get folderId;
  @override
  String get type;
  @override // 'link', 'user', 'tresor'
  String? get passwordHash;
  @override
  String? get encryptedKey;
  @override
  String get permission;
  @override
  int get maxDownloads;
  @override
  int get downloadCount;
  @override
  DateTime? get expiresAt;
  @override
  bool get isRevoked;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$ShareImplCopyWith<_$ShareImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ShareRecipient _$ShareRecipientFromJson(Map<String, dynamic> json) {
  return _ShareRecipient.fromJson(json);
}

/// @nodoc
mixin _$ShareRecipient {
  String get id => throw _privateConstructorUsedError;
  String get shareId => throw _privateConstructorUsedError;
  String get recipientId => throw _privateConstructorUsedError;
  String? get encryptedKey => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ShareRecipientCopyWith<ShareRecipient> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShareRecipientCopyWith<$Res> {
  factory $ShareRecipientCopyWith(
          ShareRecipient value, $Res Function(ShareRecipient) then) =
      _$ShareRecipientCopyWithImpl<$Res, ShareRecipient>;
  @useResult
  $Res call(
      {String id,
      String shareId,
      String recipientId,
      String? encryptedKey,
      DateTime? createdAt});
}

/// @nodoc
class _$ShareRecipientCopyWithImpl<$Res, $Val extends ShareRecipient>
    implements $ShareRecipientCopyWith<$Res> {
  _$ShareRecipientCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? shareId = null,
    Object? recipientId = null,
    Object? encryptedKey = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      shareId: null == shareId
          ? _value.shareId
          : shareId // ignore: cast_nullable_to_non_nullable
              as String,
      recipientId: null == recipientId
          ? _value.recipientId
          : recipientId // ignore: cast_nullable_to_non_nullable
              as String,
      encryptedKey: freezed == encryptedKey
          ? _value.encryptedKey
          : encryptedKey // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ShareRecipientImplCopyWith<$Res>
    implements $ShareRecipientCopyWith<$Res> {
  factory _$$ShareRecipientImplCopyWith(_$ShareRecipientImpl value,
          $Res Function(_$ShareRecipientImpl) then) =
      __$$ShareRecipientImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String shareId,
      String recipientId,
      String? encryptedKey,
      DateTime? createdAt});
}

/// @nodoc
class __$$ShareRecipientImplCopyWithImpl<$Res>
    extends _$ShareRecipientCopyWithImpl<$Res, _$ShareRecipientImpl>
    implements _$$ShareRecipientImplCopyWith<$Res> {
  __$$ShareRecipientImplCopyWithImpl(
      _$ShareRecipientImpl _value, $Res Function(_$ShareRecipientImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? shareId = null,
    Object? recipientId = null,
    Object? encryptedKey = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$ShareRecipientImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      shareId: null == shareId
          ? _value.shareId
          : shareId // ignore: cast_nullable_to_non_nullable
              as String,
      recipientId: null == recipientId
          ? _value.recipientId
          : recipientId // ignore: cast_nullable_to_non_nullable
              as String,
      encryptedKey: freezed == encryptedKey
          ? _value.encryptedKey
          : encryptedKey // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ShareRecipientImpl implements _ShareRecipient {
  const _$ShareRecipientImpl(
      {required this.id,
      required this.shareId,
      required this.recipientId,
      this.encryptedKey,
      this.createdAt});

  factory _$ShareRecipientImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShareRecipientImplFromJson(json);

  @override
  final String id;
  @override
  final String shareId;
  @override
  final String recipientId;
  @override
  final String? encryptedKey;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'ShareRecipient(id: $id, shareId: $shareId, recipientId: $recipientId, encryptedKey: $encryptedKey, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShareRecipientImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.shareId, shareId) || other.shareId == shareId) &&
            (identical(other.recipientId, recipientId) ||
                other.recipientId == recipientId) &&
            (identical(other.encryptedKey, encryptedKey) ||
                other.encryptedKey == encryptedKey) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, shareId, recipientId, encryptedKey, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ShareRecipientImplCopyWith<_$ShareRecipientImpl> get copyWith =>
      __$$ShareRecipientImplCopyWithImpl<_$ShareRecipientImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShareRecipientImplToJson(
      this,
    );
  }
}

abstract class _ShareRecipient implements ShareRecipient {
  const factory _ShareRecipient(
      {required final String id,
      required final String shareId,
      required final String recipientId,
      final String? encryptedKey,
      final DateTime? createdAt}) = _$ShareRecipientImpl;

  factory _ShareRecipient.fromJson(Map<String, dynamic> json) =
      _$ShareRecipientImpl.fromJson;

  @override
  String get id;
  @override
  String get shareId;
  @override
  String get recipientId;
  @override
  String? get encryptedKey;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$ShareRecipientImplCopyWith<_$ShareRecipientImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
