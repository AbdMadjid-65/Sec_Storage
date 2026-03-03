// ============================================================
// PriVault – User Model
// ============================================================

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String plan; // 'free', 'plus', 'family'
  final int storageUsedBytes;
  final int storageMaxBytes;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool is2faEnabled;
  final String? publicKey;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.plan = 'free',
    this.storageUsedBytes = 0,
    this.storageMaxBytes = 5368709120, // 5 GB
    required this.createdAt,
    this.lastLoginAt,
    this.is2faEnabled = false,
    this.publicKey,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      plan: json['plan'] as String? ?? 'free',
      storageUsedBytes: json['storage_used_bytes'] as int? ?? 0,
      storageMaxBytes: json['storage_max_bytes'] as int? ?? 5368709120,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      is2faEnabled: json['is_2fa_enabled'] as bool? ?? false,
      publicKey: json['public_key'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'plan': plan,
      'storage_used_bytes': storageUsedBytes,
      'storage_max_bytes': storageMaxBytes,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_2fa_enabled': is2faEnabled,
      'public_key': publicKey,
    };
  }
}
