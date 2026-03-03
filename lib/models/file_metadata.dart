import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_metadata.freezed.dart';
part 'file_metadata.g.dart';

@freezed
class FileMetadata with _$FileMetadata {
  const factory FileMetadata({
    required String id,
    required String userId,
    String? folderId,
    required String name, // Encrypted filename
    required String encryptedName, // Original filename, encrypted
    @Default('application/octet-stream') String mimeType,
    @Default(0) int sizeBytes,
    required String storagePath,
    String? thumbnailPath,
    @Default(false) bool isFavorite,
    @Default(false) bool isDeleted,
    DateTime? deletedAt,
    @Default(1) int version,
    String? encryptionIv,
    String? fileKeyEncrypted,
    String? checksum,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _FileMetadata;

  factory FileMetadata.fromJson(Map<String, dynamic> json) =>
      _$FileMetadataFromJson(json);
}
