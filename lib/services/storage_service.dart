// ============================================================
// PriVault – Storage Service (Firebase)
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseFirestore _firestore;

  StorageService(this._firestore);

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  /// Get current storage usage.
  Future<Map<String, dynamic>> getUsage() async {
    final doc = await _firestore.collection('users').doc(_uid).get();
    final data = doc.data() ?? {};
    // Read both camelCase (new) and snake_case (legacy) field names
    final usedBytes = (data['storageUsedBytes'] ?? data['storage_used_bytes'] as num?)?.toInt() ?? 0;
    final maxBytes = (data['storageMaxBytes'] ?? data['storage_max_bytes'] as num?)?.toInt() ?? 3221225472;
    return {
      'storageUsedBytes': usedBytes,
      'storageMaxBytes': maxBytes,
      'remainingBytes': maxBytes - usedBytes,
    };
  }

  /// Get full quota info.
  Future<Map<String, dynamic>> getQuota() async {
    return getUsage();
  }

  /// Check if uploading a file of the given size is allowed.
  Future<bool> canUpload(int sizeBytes) async {
    final usage = await getUsage();
    final remaining = usage['remainingBytes'] as int? ?? 0;
    return sizeBytes <= remaining;
  }
}
