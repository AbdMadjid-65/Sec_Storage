// ============================================================
// PriVault – Audit Service (BR-16, BR-17)
// ============================================================
// Logs user actions to the Firestore 'auditLogs' collection.
// ============================================================

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuditService {
  final FirebaseFirestore _firestore;

  AuditService(this._firestore);

  /// Log an action to the auditLogs collection.
  ///
  /// [action] — e.g. 'auth.login', 'file.upload', 'share.create'
  /// [metadata] — optional extra data about the action
  Future<void> log({
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final entry = <String, dynamic>{
        'userId': user.uid,
        'email': user.email ?? '',
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceType': _getDeviceType(),
        if (metadata != null) 'metadata': metadata,
      };

      await _firestore.collection('auditLogs').add(entry);
    } catch (e) {
      // Audit logging should never break the app — silently fail
      debugPrint('AuditService.log failed: $e');
    }
  }

  String _getDeviceType() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
}
