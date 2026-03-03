import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String email,
    String? displayName,
    String? avatarUrl,
    @Default('free') String plan,
    @Default(0) int storageUsedBytes,
    @Default(5368709120) int storageMaxBytes,
    String? publicKey,
    String? encryptedPrivateKey,
    String? salt,
    @Default(false) bool is2faEnabled,
    String? totpSecretEncrypted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
