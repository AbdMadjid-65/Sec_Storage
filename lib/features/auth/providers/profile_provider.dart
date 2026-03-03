// ============================================================
// PriVault – Profile Provider (Riverpod)
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/repositories/profile_repository.dart';

/// ProfileRepository provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final api = ref.read(apiClientProvider);
  return ProfileRepository(api);
});

/// Current user's profile provider.
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repo = ref.read(profileRepositoryProvider);
  try {
    return await repo.getMyProfile();
  } catch (_) {
    return null;
  }
});
