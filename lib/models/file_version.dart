/// Model for a file version entry in the `file_versions` table.
class FileVersion {
  final String id;
  final String fileId;
  final int versionNumber;
  final String cloudinaryUrl;
  final int sizeBytes;
  final String uploadedBy;
  final String? encryptionIv;
  final String? fileKeyEncrypted;
  final DateTime? createdAt;

  const FileVersion({
    required this.id,
    required this.fileId,
    required this.versionNumber,
    required this.cloudinaryUrl,
    required this.sizeBytes,
    required this.uploadedBy,
    this.encryptionIv,
    this.fileKeyEncrypted,
    this.createdAt,
  });

  factory FileVersion.fromJson(Map<String, dynamic> json) {
    return FileVersion(
      id: json['id'] as String,
      fileId: json['file_id'] as String,
      versionNumber: json['version_number'] as int,
      cloudinaryUrl: json['cloudinary_url'] as String,
      sizeBytes: json['size_bytes'] as int,
      uploadedBy: json['uploaded_by'] as String,
      encryptionIv: json['encryption_iv'] as String?,
      fileKeyEncrypted: json['file_key_encrypted'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_id': fileId,
      'version_number': versionNumber,
      'cloudinary_url': cloudinaryUrl,
      'size_bytes': sizeBytes,
      'uploaded_by': uploadedBy,
      'encryption_iv': encryptionIv,
      'file_key_encrypted': fileKeyEncrypted,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
