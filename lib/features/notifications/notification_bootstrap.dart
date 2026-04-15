import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:pri_vault/services/notification_service.dart';

/// Shows local notifications when new rows appear for the current user.
class NotificationBootstrap extends StatefulWidget {
  final Widget child;

  const NotificationBootstrap({super.key, required this.child});

  @override
  State<NotificationBootstrap> createState() => _NotificationBootstrapState();
}

class _NotificationBootstrapState extends State<NotificationBootstrap> {
  final Set<String> _seen = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  StreamSubscription<User?>? _authSub;
  bool _firstSnapshot = true;

  @override
  void initState() {
    super.initState();
    _bind();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      _firstSnapshot = true;
      _seen.clear();
      _bind();
    });
  }

  void _bind() {
    _sub?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _sub = FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
      if (_firstSnapshot) {
        _firstSnapshot = false;
        for (final d in snap.docs) {
          _seen.add(d.id);
        }
        return;
      }
      for (final ch in snap.docChanges) {
        if (ch.type == DocumentChangeType.added) {
          final id = ch.doc.id;
          if (_seen.contains(id)) continue;
          _seen.add(id);
          final d = ch.doc.data();
          if (d != null) {
            final pause = Hive.box('settings').get('pauseNotifications', defaultValue: false) == true;
            if (!pause) {
              NotificationService.showLocalFromMap(d);
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
