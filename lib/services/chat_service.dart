// ============================================================
// PriVault – Chat (Firestore + encrypted payloads)
// ============================================================

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';
import 'package:pri_vault/core/encryption/encryption_service.dart';
import 'package:pri_vault/services/vault_service.dart';

/// Riverpod provider for [ChatService].
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(
    ref.read(firestoreProvider),
    VaultService(),
    EncryptionService(),
  );
});

class ChatService {
  ChatService(this._firestore, this._vault, this._encryption);

  final FirebaseFirestore _firestore;
  final VaultService _vault;
  final EncryptionService _encryption;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static String directChatId(String a, String b) {
    final u = [a, b]..sort();
    return 'direct_${u[0]}_${u[1]}';
  }

  Future<Uint8List> _chatKey() async {
    final seedBase64 = await _vault.getMasterKeySeed();
    if (seedBase64 == null) {
      throw StateError('Master key not available');
    }
    final masterKey = CryptoUtils.fromBase64(seedBase64);
    return _encryption.deriveSubKey(
      masterKey: masterKey,
      info: 'pri_vault_chat_v1',
    );
  }

  Future<String> encryptText(String plain) async {
    final key = await _chatKey();
    final packed = await _encryption.encrypt(
      plaintext: Uint8List.fromList(utf8.encode(plain)),
      key: key,
    );
    return CryptoUtils.toBase64(packed);
  }

  Future<String> decryptText(String b64) async {
    final key = await _chatKey();
    final plain = await _encryption.decrypt(
      ciphertext: CryptoUtils.fromBase64(b64),
      key: key,
    );
    return utf8.decode(plain);
  }

  /// Ensure a direct chat document exists for two users.
  Future<void> ensureDirectChat(String otherUid) async {
    final me = _uid;
    if (me == null) return;
    final id = directChatId(me, otherUid);
    final ref = _firestore.collection('chats').doc(id);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'members': [me, otherUid],
      'type': 'direct',
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMyChats() {
    final me = _uid;
    if (me == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('chats')
        .where('members', arrayContains: me)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> sendMessage({
    required String chatId,
    required String plainText,
  }) async {
    final me = _uid;
    if (me == null) return;
    final enc = await encryptText(plainText);
    final batch = _firestore.batch();
    final msgRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
    batch.set(msgRef, {
      'senderId': me,
      'text': enc,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [me],
    });
    batch.set(
      _firestore.collection('chats').doc(chatId),
      {
        'lastMessage': plainText.length > 120
            ? '${plainText.substring(0, 117)}...'
            : plainText,
        'lastMessageAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> markRead(String chatId) async {
    final me = _uid;
    if (me == null) return;
    debugPrint('[Chat] markRead $chatId');
  }

  // --- Friendships ---

  Stream<QuerySnapshot<Map<String, dynamic>>> streamFriendships() {
    final me = _uid;
    if (me == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('friendships')
        .where('participants', arrayContains: me)
        .snapshots();
  }

  Future<void> sendFriendRequest(String targetUid) async {
    final me = _uid;
    if (me == null || targetUid == me) return;
    final u = [me, targetUid]..sort();
    final docId = '${u[0]}_${u[1]}';
    await _firestore.collection('friendships').doc(docId).set({
      'participants': [me, targetUid],
      'user1': u[0],
      'user2': u[1],
      'status': 'pending',
      'requestedBy': me,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptFriendRequest(String friendDocId) async {
    final me = _uid;
    if (me == null) return;
    final snap =
        await _firestore.collection('friendships').doc(friendDocId).get();
    final d = snap.data();
    if (d == null) return;
    await _firestore.collection('friendships').doc(friendDocId).update({
      'status': 'accepted',
    });
    final u1 = d['user1'] as String?;
    final u2 = d['user2'] as String?;
    if (u1 != null && u2 != null) {
      final other = u1 == me ? u2 : u1;
      await ensureDirectChat(other);
    }
  }

  Future<void> declineFriendRequest(String friendDocId) async {
    await _firestore.collection('friendships').doc(friendDocId).delete();
  }

  /// Exact match on [displayName] (username).
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> searchUsersByDisplayName(
    String query,
  ) async {
    final me = _uid;
    if (me == null || query.trim().isEmpty) return [];
    final q = await _firestore
        .collection('users')
        .where('displayName', isEqualTo: query.trim())
        .limit(20)
        .get();
    return q.docs.where((d) => d.id != me).toList();
  }
}
