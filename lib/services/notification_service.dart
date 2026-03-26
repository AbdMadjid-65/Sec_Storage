import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore;

  NotificationService(this._firestore);

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMyNotifications() {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: _uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markAllRead() async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: _uid)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  Future<void> notifyFileEvent({
    String? recipientId,
    String? recipientEmail,
    required String type,
    required String fileId,
    required String fileName,
    required String actorId,
    required String actorName,
  }) async {
    String? resolvedRecipientId = recipientId;
    if (resolvedRecipientId == null && recipientEmail != null && recipientEmail.isNotEmpty) {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: recipientEmail)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        resolvedRecipientId = query.docs.first.id;
      }
    }
    if (resolvedRecipientId == null) return;

    await _firestore.collection('notifications').add({
      'recipientId': resolvedRecipientId,
      'type': type,
      'fileId': fileId,
      'fileName': fileName,
      'actor': {
        'id': actorId,
        'name': actorName,
      },
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }
}
