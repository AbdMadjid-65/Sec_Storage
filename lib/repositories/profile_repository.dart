// ============================================================
// PriVault – Profile Repository (HTTP API)
// ============================================================

import 'package:pri_vault/core/api/api_client.dart';

class ProfileRepository {
  final ApiClient _api;

  ProfileRepository(this._api);

  Future<Map<String, dynamic>> getMyProfile() async {
    return await _api.get('/profiles/me');
  }

  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? publicKey,
    String? salt,
  }) async {
    return await _api.put('/profiles/me', body: {
      if (displayName != null) 'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (publicKey != null) 'public_key': publicKey,
      if (salt != null) 'salt': salt,
    });
  }
}
