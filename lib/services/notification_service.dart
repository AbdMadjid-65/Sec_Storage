import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService(this._firestore);

  final FirebaseFirestore _firestore;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initLocalNotifications() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<void> _showLocal({
    required String title,
    required String body,
  }) async {
    try {
      await initLocalNotifications();
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'pri_vault_main',
          'PriVault',
          channelDescription: 'PriVault alerts',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _local.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('[NotificationService] local show failed: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMyNotifications() {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: _uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<int> streamUnreadCount() {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: _uid)
        .snapshots()
        .map((s) => s.docs.where((d) => d.data()['isRead'] != true).length);
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

  Future<void> _addDoc({
    required String recipientId,
    required String type,
    required String title,
    required String body,
    String? fileId,
    String? actorId,
    String? actorName,
  }) async {
    await _firestore.collection('notifications').add({
      'recipientId': recipientId,
      'type': type,
      'title': title,
      'body': body,
      if (fileId != null) 'fileId': fileId,
      if (actorId != null) 'actorId': actorId,
      if (actorName != null) 'actorName': actorName,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
    if (recipientId == _uid) {
      await _showLocal(title: title, body: body);
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
    if (resolvedRecipientId == null &&
        recipientEmail != null &&
        recipientEmail.isNotEmpty) {
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

    final title = _titleForType(type);
    final body = '$actorName — $fileName';

    await _firestore.collection('notifications').add({
      'recipientId': resolvedRecipientId,
      'type': type,
      'title': title,
      'body': body,
      'fileId': fileId,
      'actorId': actorId,
      'actorName': actorName,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    if (resolvedRecipientId == _uid) {
      await _showLocal(title: title, body: body);
    }
  }

  String _titleForType(String type) {
    switch (type) {
      case 'file_shared_with_user':
        return 'File shared';
      case 'file_viewed':
        return 'File viewed';
      case 'file_downloaded':
        return 'File downloaded';
      case 'new_comment':
        return 'New comment';
      case 'share_expired':
        return 'Share expired';
      case 'friend_request':
        return 'Friend request';
      case 'friend_accepted':
        return 'Friend request accepted';
      default:
        return 'PriVault';
    }
  }

  Future<void> notifyFriendRequest({
    required String recipientId,
    required String actorId,
    required String actorName,
  }) async {
    await _addDoc(
      recipientId: recipientId,
      type: 'friend_request',
      title: 'Friend request',
      body: '$actorName wants to be your friend',
      actorId: actorId,
      actorName: actorName,
    );
  }

  /// Call when the current user accepts a request — notifies the original requester.
  Future<void> notifyFriendRequestAccepted({required String requesterUid}) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    final doc = await _firestore.collection('users').doc(me.uid).get();
    final name = doc.data()?['displayName'] ??
        doc.data()?['display_name'] ??
        me.displayName ??
        'Someone';
    await _addDoc(
      recipientId: requesterUid,
      type: 'friend_accepted',
      title: 'Friend request accepted',
      body: '$name accepted your friend request',
      actorId: me.uid,
      actorName: name.toString(),
    );
  }

  /// Show a local notification from Firestore payload (used by foreground listener).
  static Future<void> showLocalFromMap(Map<String, dynamic> data) async {
    final title = data['title'] as String? ?? 'PriVault';
    final body = data['body'] as String? ?? '';
    try {
      await initLocalNotifications();
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'pri_vault_main',
          'PriVault',
          channelDescription: 'PriVault alerts',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _local.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('[NotificationService] showLocalFromMap: $e');
    }
  }

  Future<void> notifyFileViewed({
    required String ownerUid,
    required String fileId,
    required String fileName,
    required String viewerUid,
    required String viewerName,
  }) async {
    await _addDoc(
      recipientId: ownerUid,
      type: 'file_viewed',
      title: 'File viewed',
      body: '$viewerName viewed your file "$fileName"',
      fileId: fileId,
      actorId: viewerUid,
      actorName: viewerName,
    );
  }

  Future<void> notifyFileDownloaded({
    required String ownerUid,
    required String fileId,
    required String fileName,
    required String actorUid,
    required String actorName,
  }) async {
    await _addDoc(
      recipientId: ownerUid,
      type: 'file_downloaded',
      title: 'File downloaded',
      body: '$actorName downloaded your file "$fileName"',
      fileId: fileId,
      actorId: actorUid,
      actorName: actorName,
    );
  }

  Future<void> notifyNewComment({
    required String ownerUid,
    required String fileId,
    required String fileName,
    required String actorUid,
    required String actorName,
  }) async {
    await _addDoc(
      recipientId: ownerUid,
      type: 'new_comment',
      title: 'New comment',
      body: '$actorName commented on "$fileName"',
      fileId: fileId,
      actorId: actorUid,
      actorName: actorName,
    );
  }

  Future<void> notifyShareExpired({
    required String ownerUid,
    required String fileId,
    required String fileName,
  }) async {
    await _addDoc(
      recipientId: ownerUid,
      type: 'share_expired',
      title: 'Share expired',
      body: 'Your shared link for "$fileName" has expired',
      fileId: fileId,
    );
  }
}
