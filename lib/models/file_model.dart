// ============================================================
// PriVault – File Model
// ============================================================

class FileModel {
  final String id;
  final String userId;
  final String? folderId;
  final String name;
  final String encryptedName;
  final String mimeType;
  final int sizeBytes;
  final String storagePath;
  final String? thumbnailPath;
  final bool isFavorite;
  final bool isDeleted;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const FileModel({
    required this.id,
    required this.userId,
    this.folderId,
    required this.name,
    required this.encryptedName,
    required this.mimeType,
    required this.sizeBytes,
    required this.storagePath,
    this.thumbnailPath,
    this.isFavorite = false,
    this.isDeleted = false,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      folderId: json['folder_id'] as String?,
      name: json['name'] as String,
      encryptedName: json['encrypted_name'] as String,
      mimeType: json['mime_type'] as String,
      sizeBytes: json['size_bytes'] as int,
      storagePath: json['storage_path'] as String,
      thumbnailPath: json['thumbnail_path'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      version: json['version'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'folder_id': folderId,
      'name': name,
      'encrypted_name': encryptedName,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
      'storage_path': storagePath,
      'thumbnail_path': thumbnailPath,
      'is_favorite': isFavorite,
      'is_deleted': isDeleted,
      'version': version,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
