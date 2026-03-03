// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FileMetadata _$FileMetadataFromJson(Map<String, dynamic> json) {
  return _FileMetadata.fromJson(json);
}

/// @nodoc
mixin _$FileMetadata {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String? get folderId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError; // Encrypted filename
  String get encryptedName =>
      throw _privateConstructorUsedError; // Original filename, encrypted
  String get mimeType => throw _privateConstructorUsedError;
  int get sizeBytes => throw _privateConstructorUsedError;
  String get storagePath => throw _privateConstructorUsedError;
  String? get thumbnailPath => throw _privateConstructorUsedError;
  bool get isFavorite => throw _privateConstructorUsedError;
  bool get isDeleted => throw _privateConstructorUsedError;
  DateTime? get deletedAt => throw _privateConstructorUsedError;
  int get version => throw _privateConstructorUsedError;
  String? get encryptionIv => throw _privateConstructorUsedError;
  String? get fileKeyEncrypted => throw _privateConstructorUsedError;
  String? get checksum => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FileMetadataCopyWith<FileMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FileMetadataCopyWith<$Res> {
  factory $FileMetadataCopyWith(
          FileMetadata value, $Res Function(FileMetadata) then) =
      _$FileMetadataCopyWithImpl<$Res, FileMetadata>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String? folderId,
      String name,
      String encryptedName,
      String mimeType,
      int sizeBytes,
      String storagePath,
      String? thumbnailPath,
      bool isFavorite,
      bool isDeleted,
      DateTime? deletedAt,
      int version,
      String? encryptionIv,
      String? fileKeyEncrypted,
      String? checksum,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$FileMetadataCopyWithImpl<$Res, $Val extends FileMetadata>
    implements $FileMetadataCopyWith<$Res> {
  _$FileMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? folderId = freezed,
    Object? name = null,
    Object? encryptedName = null,
    Object? mimeType = null,
    Object? sizeBytes = null,
    Object? storagePath = null,
    Object? thumbnailPath = freezed,
    Object? isFavorite = null,
    Object? isDeleted = null,
    Object? deletedAt = freezed,
    Object? version = null,
    Object? encryptionIv = freezed,
    Object? fileKeyEncrypted = freezed,
    Object? checksum = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      folderId: freezed == folderId
          ? _value.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      encryptedName: null == encryptedName
          ? _value.encryptedName
          : encryptedName // ignore: cast_nullable_to_non_nullable
              as String,
      mimeType: null == mimeType
          ? _value.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String,
      sizeBytes: null == sizeBytes
          ? _value.sizeBytes
          : sizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      storagePath: null == storagePath
          ? _value.storagePath
          : storagePath // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailPath: freezed == thumbnailPath
          ? _value.thumbnailPath
          : thumbnailPath // ignore: cast_nullable_to_non_nullable
              as String?,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      encryptionIv: freezed == encryptionIv
          ? _value.encryptionIv
          : encryptionIv // ignore: cast_nullable_to_non_nullable
              as String?,
      fileKeyEncrypted: freezed == fileKeyEncrypted
          ? _value.fileKeyEncrypted
          : fileKeyEncrypted // ignore: cast_nullable_to_non_nullable
              as String?,
      checksum: freezed == checksum
          ? _value.checksum
          : checksum // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FileMetadataImplCopyWith<$Res>
    implements $FileMetadataCopyWith<$Res> {
  factory _$$FileMetadataImplCopyWith(
          _$FileMetadataImpl value, $Res Function(_$FileMetadataImpl) then) =
      __$$FileMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String? folderId,
      String name,
      String encryptedName,
      String mimeType,
      int sizeBytes,
      String storagePath,
      String? thumbnailPath,
      bool isFavorite,
      bool isDeleted,
      DateTime? deletedAt,
      int version,
      String? encryptionIv,
      String? fileKeyEncrypted,
      String? checksum,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$FileMetadataImplCopyWithImpl<$Res>
    extends _$FileMetadataCopyWithImpl<$Res, _$FileMetadataImpl>
    implements _$$FileMetadataImplCopyWith<$Res> {
  __$$FileMetadataImplCopyWithImpl(
      _$FileMetadataImpl _value, $Res Function(_$FileMetadataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? folderId = freezed,
    Object? name = null,
    Object? encryptedName = null,
    Object? mimeType = null,
    Object? sizeBytes = null,
    Object? storagePath = null,
    Object? thumbnailPath = freezed,
    Object? isFavorite = null,
    Object? isDeleted = null,
    Object? deletedAt = freezed,
    Object? version = null,
    Object? encryptionIv = freezed,
    Object? fileKeyEncrypted = freezed,
    Object? checksum = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$FileMetadataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      folderId: freezed == folderId
          ? _value.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      encryptedName: null == encryptedName
          ? _value.encryptedName
          : encryptedName // ignore: cast_nullable_to_non_nullable
              as String,
      mimeType: null == mimeType
          ? _value.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String,
      sizeBytes: null == sizeBytes
          ? _value.sizeBytes
          : sizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      storagePath: null == storagePath
          ? _value.storagePath
          : storagePath // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailPath: freezed == thumbnailPath
          ? _value.thumbnailPath
          : thumbnailPath // ignore: cast_nullable_to_non_nullable
              as String?,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      encryptionIv: freezed == encryptionIv
          ? _value.encryptionIv
          : encryptionIv // ignore: cast_nullable_to_non_nullable
              as String?,
      fileKeyEncrypted: freezed == fileKeyEncrypted
          ? _value.fileKeyEncrypted
          : fileKeyEncrypted // ignore: cast_nullable_to_non_nullable
              as String?,
      checksum: freezed == checksum
          ? _value.checksum
          : checksum // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FileMetadataImpl implements _FileMetadata {
  const _$FileMetadataImpl(
      {required this.id,
      required this.userId,
      this.folderId,
      required this.name,
      required this.encryptedName,
      this.mimeType = 'application/octet-stream',
      this.sizeBytes = 0,
      required this.storagePath,
      this.thumbnailPath,
      this.isFavorite = false,
      this.isDeleted = false,
      this.deletedAt,
      this.version = 1,
      this.encryptionIv,
      this.fileKeyEncrypted,
      this.checksum,
      this.createdAt,
      this.updatedAt});

  factory _$FileMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$FileMetadataImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String? folderId;
  @override
  final String name;
// Encrypted filename
  @override
  final String encryptedName;
// Original filename, encrypted
  @override
  @JsonKey()
  final String mimeType;
  @override
  @JsonKey()
  final int sizeBytes;
  @override
  final String storagePath;
  @override
  final String? thumbnailPath;
  @override
  @JsonKey()
  final bool isFavorite;
  @override
  @JsonKey()
  final bool isDeleted;
  @override
  final DateTime? deletedAt;
  @override
  @JsonKey()
  final int version;
  @override
  final String? encryptionIv;
  @override
  final String? fileKeyEncrypted;
  @override
  final String? checksum;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'FileMetadata(id: $id, userId: $userId, folderId: $folderId, name: $name, encryptedName: $encryptedName, mimeType: $mimeType, sizeBytes: $sizeBytes, storagePath: $storagePath, thumbnailPath: $thumbnailPath, isFavorite: $isFavorite, isDeleted: $isDeleted, deletedAt: $deletedAt, version: $version, encryptionIv: $encryptionIv, fileKeyEncrypted: $fileKeyEncrypted, checksum: $checksum, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileMetadataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.folderId, folderId) ||
                other.folderId == folderId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.encryptedName, encryptedName) ||
                other.encryptedName == encryptedName) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.sizeBytes, sizeBytes) ||
                other.sizeBytes == sizeBytes) &&
            (identical(other.storagePath, storagePath) ||
                other.storagePath == storagePath) &&
            (identical(other.thumbnailPath, thumbnailPath) ||
                other.thumbnailPath == thumbnailPath) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.encryptionIv, encryptionIv) ||
                other.encryptionIv == encryptionIv) &&
            (identical(other.fileKeyEncrypted, fileKeyEncrypted) ||
                other.fileKeyEncrypted == fileKeyEncrypted) &&
            (identical(other.checksum, checksum) ||
                other.checksum == checksum) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      folderId,
      name,
      encryptedName,
      mimeType,
      sizeBytes,
      storagePath,
      thumbnailPath,
      isFavorite,
      isDeleted,
      deletedAt,
      version,
      encryptionIv,
      fileKeyEncrypted,
      checksum,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FileMetadataImplCopyWith<_$FileMetadataImpl> get copyWith =>
      __$$FileMetadataImplCopyWithImpl<_$FileMetadataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FileMetadataImplToJson(
      this,
    );
  }
}

abstract class _FileMetadata implements FileMetadata {
  const factory _FileMetadata(
      {required final String id,
      required final String userId,
      final String? folderId,
      required final String name,
      required final String encryptedName,
      final String mimeType,
      final int sizeBytes,
      required final String storagePath,
      final String? thumbnailPath,
      final bool isFavorite,
      final bool isDeleted,
      final DateTime? deletedAt,
      final int version,
      final String? encryptionIv,
      final String? fileKeyEncrypted,
      final String? checksum,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$FileMetadataImpl;

  factory _FileMetadata.fromJson(Map<String, dynamic> json) =
      _$FileMetadataImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String? get folderId;
  @override
  String get name;
  @override // Encrypted filename
  String get encryptedName;
  @override // Original filename, encrypted
  String get mimeType;
  @override
  int get sizeBytes;
  @override
  String get storagePath;
  @override
  String? get thumbnailPath;
  @override
  bool get isFavorite;
  @override
  bool get isDeleted;
  @override
  DateTime? get deletedAt;
  @override
  int get version;
  @override
  String? get encryptionIv;
  @override
  String? get fileKeyEncrypted;
  @override
  String? get checksum;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$FileMetadataImplCopyWith<_$FileMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
