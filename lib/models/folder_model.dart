// ============================================================
// PriVault – Folder Model
// ============================================================

class FolderModel {
  final String id;
  final String userId;
  final String? parentId;
  final String name;
  final String? color;
  final bool isShared;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FolderModel({
    required this.id,
    required this.userId,
    this.parentId,
    required this.name,
    this.color,
    this.isShared = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      parentId: json['parent_id'] as String?,
      name: json['name'] as String,
      color: json['color'] as String?,
      isShared: json['is_shared'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'parent_id': parentId,
      'name': name,
      'color': color,
      'is_shared': isShared,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
