// ============================================================
// PriVault – Share Repository (Firebase)
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pri_vault/models/file_metadata.dart';
import 'package:pri_vault/models/share_models.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';
import 'package:pri_vault/core/encryption/encryption_service.dart';
import 'package:uuid/uuid.dart';

class ShareRepository {
  final FirebaseFirestore _firestore;
  final EncryptionService _encryptionService;

  ShareRepository(this._firestore, this._encryptionService);

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  String? get _email => FirebaseAuth.instance.currentUser?.email;

  Future<String> createTeam({required String name}) async {
    final teamRef = _firestore.collection('teams').doc();
    await teamRef.set({
      'name': name,
      'owner_id': _uid,
      'created_at': FieldValue.serverTimestamp(),
    });
    await addTeamMember(teamId: teamRef.id, memberIdentifier: _email ?? _uid);
    return teamRef.id;
  }

  Future<void> addTeamMember({
    required String teamId,
    required String memberIdentifier,
  }) async {
    String memberUid = memberIdentifier;
    if (memberIdentifier.contains('@')) {
      final userSnap = await _firestore
          .collection('users')
          .where('email', isEqualTo: memberIdentifier)
          .limit(1)
          .get();
      if (userSnap.docs.isEmpty) throw Exception('Member not found');
      memberUid = userSnap.docs.first.id;
    }
    await _firestore.collection('teamMembers').add({
      'team_id': teamId,
      'user_id': memberUid,
      'added_by': _uid,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getMyTeams() async {
    final membership = await _firestore
        .collection('teamMembers')
        .where('user_id', isEqualTo: _uid)
        .get();
    final ids = membership.docs
        .map((e) => e.data()['team_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final teams = <Map<String, dynamic>>[];
    for (final id in ids) {
      final doc = await _firestore.collection('teams').doc(id).get();
      if (doc.exists) {
        teams.add({'id': doc.id, ...doc.data()!});
      }
    }
    return teams;
  }

  // ── Create public link (BR-13, BR-14) ─────────────────────
  Future<(Share, String)> createPublicLink({
    required FileMetadata file,
    required Uint8List masterKey,
    DateTime? expiresAt,
    int maxDownloads = 0,
    String permission = 'view',
  }) async {
    if (file.fileKeyEncrypted == null) throw Exception('File key missing');

    final encryptedFileKeyBytes =
        CryptoUtils.fromBase64(file.fileKeyEncrypted!);
    final fileKey = await _encryptionService.decrypt(
      ciphertext: encryptedFileKeyBytes,
      key: masterKey,
    );

    final linkKeyBytes = CryptoUtils.generateKey();
    final linkKeyString = CryptoUtils.toBase64(linkKeyBytes);

    final newEncryptedKeyBytes = await _encryptionService.encrypt(
      plaintext: fileKey,
      key: linkKeyBytes,
    );
    final newEncryptedKeyBase64 = CryptoUtils.toBase64(newEncryptedKeyBytes);

    final shareId = const Uuid().v4();
    await _firestore.collection('shares').doc(shareId).set({
      'owner_id': _uid,
      'owner_email': _email,
      'file_id': file.id,
      'file_name': file.name,
      'folder_id': null,
      'type': 'link',
      'encrypted_key': newEncryptedKeyBase64,
      'permission': permission,
      'max_downloads': maxDownloads,
      'download_count': 0,
      'expires_at': expiresAt?.toIso8601String(),
      'is_revoked': false,
      'created_at': FieldValue.serverTimestamp(),
    });

    final share = Share(
      id: shareId,
      ownerId: _uid,
      fileId: file.id,
      type: 'link',
      encryptedKey: newEncryptedKeyBase64,
      permission: permission,
      maxDownloads: maxDownloads,
      downloadCount: 0,
      expiresAt: expiresAt,
      isRevoked: false,
      createdAt: DateTime.now(),
    );

    return (share, linkKeyString);
  }

  // ── Share with specific user by email (BR-13) ──────────────
  Future<void> shareWithUser({
    required FileMetadata file,
    required Uint8List masterKey,
    required Uint8List senderPrivateKey,
    required String recipientEmail,
    String permission = 'view',
    DateTime? expiresAt,
  }) async {
    if (file.fileKeyEncrypted == null) throw Exception('File key missing');

    final encryptedFileKeyBytes =
        CryptoUtils.fromBase64(file.fileKeyEncrypted!);
    final fileKey = await _encryptionService.decrypt(
      ciphertext: encryptedFileKeyBytes,
      key: masterKey,
    );

    final recipientQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: recipientEmail)
        .limit(1)
        .get();
    if (recipientQuery.docs.isEmpty) {
      throw Exception('Recipient not found');
    }
    final recipientDoc = recipientQuery.docs.first;
    final recipientId = recipientDoc.id;
    final recipientPublicKeyB64 = recipientDoc.data()['publicKey'] as String?;
    if (recipientPublicKeyB64 == null || recipientPublicKeyB64.isEmpty) {
      throw Exception('Recipient key missing');
    }

    final myKeyPair = await _encryptionService.getKeyPairFromPrivateKey(
      senderPrivateKey,
    );
    final sharedSecret = await _encryptionService.deriveSharedSecret(
      myKeyPair: myKeyPair,
      theirPublicKeyBytes: CryptoUtils.fromBase64(recipientPublicKeyB64),
    );
    final keyWrapKey = sharedSecret.sublist(0, 32);
    final recipientEncryptedKey = CryptoUtils.toBase64(
      await _encryptionService.encrypt(plaintext: fileKey, key: keyWrapKey),
    );

    final myPublicKey = await myKeyPair.extractPublicKey();

    final shareId = const Uuid().v4();
    await _firestore.collection('shares').doc(shareId).set({
      'owner_id': _uid,
      'owner_email': _email,
      'file_id': file.id,
      'file_name': file.name,
      'type': 'user',
      'target_id': recipientId,
      'shared_with_email': recipientEmail,
      'encrypted_key': recipientEncryptedKey,
      'recipient_encrypted_key': recipientEncryptedKey,
      'sender_public_key': CryptoUtils.toBase64(
        Uint8List.fromList(myPublicKey.bytes),
      ),
      'permission': permission,
      'expires_at': expiresAt?.toIso8601String(),
      'is_revoked': false,
      'created_at': FieldValue.serverTimestamp(),
    });
    await _firestore
        .collection('sharedAccess')
        .doc('${file.id}_$recipientId')
        .set({
      'file_id': file.id,
      'owner_id': _uid,
      'user_id': recipientId,
      'permission': permission,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ── Share with team (BR-13) ────────────────────────────────
  Future<void> shareWithTeam({
    required String fileId,
    required String fileName,
    required String teamId,
    String? encryptedKey,
    String permission = 'view',
    DateTime? expiresAt,
  }) async {
    final shareId = const Uuid().v4();
    await _firestore.collection('shares').doc(shareId).set({
      'owner_id': _uid,
      'owner_email': _email,
      'file_id': fileId,
      'file_name': fileName,
      'team_id': teamId,
      'type': 'team',
      'target_id': teamId,
      'encrypted_key': encryptedKey,
      'permission': permission,
      'expires_at': expiresAt?.toIso8601String(),
      'is_revoked': false,
      'created_at': FieldValue.serverTimestamp(),
    });
    final teamMembers = await _firestore
        .collection('teamMembers')
        .where('team_id', isEqualTo: teamId)
        .get();
    for (final member in teamMembers.docs) {
      final memberId = member.data()['user_id'] as String?;
      if (memberId == null) continue;
      await _firestore
          .collection('sharedAccess')
          .doc('${fileId}_$memberId')
          .set({
        'file_id': fileId,
        'owner_id': _uid,
        'user_id': memberId,
        'permission': permission,
        'expires_at': expiresAt?.toIso8601String(),
        'team_id': teamId,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Get shares for a specific file ────────────────────────
  Future<List<Share>> getSharesForFile(String fileId) async {
    final snapshot = await _firestore
        .collection('shares')
        .where('owner_id', isEqualTo: _uid)
        .where('file_id', isEqualTo: fileId)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Share.fromJson(data);
    }).toList();
  }

  // ── Get all shares owned by current user ──────────────────
  Future<List<Share>> getOwnerShares() async {
    final snapshot = await _firestore
        .collection('shares')
        .where('owner_id', isEqualTo: _uid)
        .get();
    final shares = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Share.fromJson(data);
    }).toList();
    shares.sort((a, b) {
      final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return shares;
  }

  // ── Get files shared with current user ────────────────────
  Future<List<SharedFile>> getSharedWithMe() async {
    final email = _email;
    if (email == null) return [];

    final allSharesSnapshot = await _firestore.collection('shares').get();
    final teamIds = await _resolveMyTeamIds();

    final sharedFiles = <SharedFile>[];
    final allDocs = allSharesSnapshot.docs.where((doc) {
      final data = doc.data();
      final type = data['type'] as String? ?? '';
      final byEmail = data['shared_with_email'] == email;
      final byLink = type == 'link';
      final byTeam = type == 'team' && teamIds.contains(data['team_id']);
      return byEmail || byLink || byTeam;
    }).toList();
    final seenShareIds = <String>{};

    for (final doc in allDocs) {
      if (!seenShareIds.add(doc.id)) continue;
      final data = doc.data();
      data['id'] = doc.id;
      final share = Share.fromJson(data);

      // Filter revoked/expired client-side to avoid composite-index dependency.
      if (share.isRevoked || share.isExpired) continue;

      if (share.fileId == null || share.ownerId.isEmpty) continue;

      try {
        // Get file metadata from owner's subcollection
        final fileDoc = await _firestore
            .collection('users')
            .doc(share.ownerId)
            .collection('files')
            .doc(share.fileId)
            .get();

        if (!fileDoc.exists) continue;

        final fileData = fileDoc.data()!;
        fileData['id'] = fileDoc.id;
        fileData['user_id'] = share.ownerId;
        final file = FileMetadata.fromJson(_normalizeKeys(fileData));

        // Use owner_email stored in share document (set at creation time)
        final ownerEmail = data['owner_email'] as String?;

        final recipientEncryptedKey = data['recipient_encrypted_key'] as String? ??
            data['encrypted_key'] as String?;
        sharedFiles.add(
          SharedFile(
            file: file,
            ownerEmail: ownerEmail,
            recipientShare: ShareRecipient(
              id: doc.id,
              shareId: doc.id,
              recipientId: _uid,
              encryptedKey: recipientEncryptedKey,
            ),
            parentShare: share,
          ),
        );
      } catch (e) {
        debugPrint(
          '[Share] Failed to materialize shared file ${doc.id}: $e',
        );
      }
    }

    return sharedFiles;
  }

  Future<List<String>> _resolveMyTeamIds() async {
    final snapshot = await _firestore
        .collection('teamMembers')
        .where('user_id', isEqualTo: _uid)
        .get();
    return snapshot.docs
        .map((d) => d.data()['team_id'] as String?)
        .whereType<String>()
        .toList();
  }

  // ── Revoke a share (BR-15) ────────────────────────────────
  Future<void> revokeShare(String shareId) async {
    final shareDoc = await _firestore.collection('shares').doc(shareId).get();
    final data = shareDoc.data();
    await _firestore.collection('shares').doc(shareId).update({
      'is_revoked': true,
      'revoked_at': FieldValue.serverTimestamp(),
    });
    if (data != null) {
      final fileId = data['file_id'] as String?;
      final targetId = data['target_id'] as String?;
      if (fileId != null && targetId != null) {
        await _firestore.collection('sharedAccess').doc('${fileId}_$targetId').delete();
      }
    }
  }

  // ── Update share permissions (BR-14) ─────────────────────
  Future<void> updatePermissions(
    String shareId, {
    String? permission,
    DateTime? expiresAt,
  }) async {
    final updates = <String, dynamic>{};
    if (permission != null) updates['permission'] = permission;
    if (expiresAt != null) updates['expires_at'] = expiresAt.toIso8601String();
    if (updates.isNotEmpty) {
      await _firestore.collection('shares').doc(shareId).update(updates);
    }
  }

  // ── Helpers ───────────────────────────────────────────────
  Map<String, dynamic> _normalizeKeys(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.value is Timestamp) {
        result[_toSnakeCase(entry.key)] =
            (entry.value as Timestamp).toDate().toIso8601String();
      } else {
        result[_toSnakeCase(entry.key)] = entry.value;
      }
    }
    return result;
  }

  String _toSnakeCase(String input) => input.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => '_${match.group(0)!.toLowerCase()}',
      );
}