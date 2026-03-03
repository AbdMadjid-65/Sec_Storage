// ============================================================
// PriVault – Storage Service (HTTP API)
// ============================================================

import 'package:pri_vault/core/api/api_client.dart';

class StorageService {
  final ApiClient _api;

  StorageService(this._api);

  /// Get current storage usage.
  Future<Map<String, dynamic>> getUsage() async {
    return await _api.get('/storage/usage');
  }

  /// Get full quota info (personal + company).
  Future<Map<String, dynamic>> getQuota() async {
    return await _api.get('/storage/quota');
  }

  /// Check if uploading a file of the given size is allowed.
  Future<bool> canUpload(int sizeBytes) async {
    final usage = await getUsage();
    final remaining = usage['remaining_bytes'] as int? ?? 0;
    return sizeBytes <= remaining;
  }
}
