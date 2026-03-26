// ============================================================
// PriVault – Sharing Provider (Riverpod + Firebase)
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';
import 'package:pri_vault/core/encryption/encryption_service.dart';
import 'package:pri_vault/repositories/share_repository.dart';
import 'package:pri_vault/models/file_metadata.dart';
import 'package:pri_vault/models/share_models.dart';
import 'package:pri_vault/services/audit_service.dart';
import 'package:pri_vault/services/vault_service.dart';
import 'package:pri_vault/services/notification_service.dart';

// ── Providers ─────────────────────────────────────────────────

final shareRepositoryProvider = Provider<ShareRepository>((ref) {
  final firestore = ref.read(firestoreProvider);
  final encryption = EncryptionService();
  return ShareRepository(firestore, encryption);
});

final vaultServiceProvider = Provider<VaultService>((ref) => VaultService());

final auditServiceProvider = Provider<AuditService>((ref) {
  return AuditService(ref.read(firestoreProvider));
});

final sharingNotificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.read(firestoreProvider));
});

// ── Data Providers ────────────────────────────────────────────

final fileSharesProvider =
    FutureProvider.family<List<Share>, String>((ref, fileId) async {
  return ref.read(shareRepositoryProvider).getSharesForFile(fileId);
});

final sharedWithMeProvider = FutureProvider<List<SharedFile>>((ref) async {
  return ref.read(shareRepositoryProvider).getSharedWithMe();
});

final sharedWithMeLiveProvider = StreamProvider<List<SharedFile>>((ref) async* {
  final firestore = ref.read(firestoreProvider);
  await for (final _ in firestore.collection('shares').snapshots()) {
    yield await ref.read(shareRepositoryProvider).getSharedWithMe();
  }
});

/// All shares owned by current user with their file metadata.
final ownerSharesProvider =
    FutureProvider<List<(Share, FileMetadata?)>>((ref) async {
  final repo = ref.read(shareRepositoryProvider);
  final firestore = ref.read(firestoreProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return [];

  final shares = await repo.getOwnerShares();
  final results = <(Share, FileMetadata?)>[];

  for (final share in shares) {
    FileMetadata? file;
    if (share.fileId != null) {
      try {
        final fileDoc = await firestore
            .collection('users')
            .doc(uid)
            .collection('files')
            .doc(share.fileId)
            .get();
        if (fileDoc.exists) {
          final data = fileDoc.data()!;
          data['id'] = fileDoc.id;
          data['user_id'] = uid;
          file = FileMetadata.fromJson(_normalizeKeys(data));
        }
      } catch (_) {}
    }
    results.add((share, file));
  }
  return results;
});

final mySharesProvider = FutureProvider<List<Share>>((ref) async {
  return ref.read(shareRepositoryProvider).getOwnerShares();
});

final myTeamsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(shareRepositoryProvider).getMyTeams();
});

// ── Sharing State ─────────────────────────────────────────────

class SharingState {
  final bool isLoading;
  final String? error;
  const SharingState({this.isLoading = false, this.error});
}

// ── Sharing Notifier ──────────────────────────────────────────

class SharingNotifier extends StateNotifier<SharingState> {
  final Ref _ref;

  SharingNotifier(this._ref) : super(const SharingState());

  AuditService get _audit => _ref.read(auditServiceProvider);
  NotificationService get _notifications => _ref.read(sharingNotificationServiceProvider);

  /// Create a public link (BR-13) + audit log
  Future<String?> createPublicLink(
    FileMetadata file, {
    String permission = 'view',
    DateTime? expiresAt,
    int maxDownloads = 0,
  }) async {
    state = const SharingState(isLoading: true);
    try {
      final vault = _ref.read(vaultServiceProvider);
      final repo = _ref.read(shareRepositoryProvider);

      final seed = await vault.getMasterKeySeed();
      if (seed == null) throw Exception('No master key found');
      final masterKey = CryptoUtils.fromBase64(seed);

      final (share, linkKey) = await repo.createPublicLink(
        file: file,
        masterKey: masterKey,
        permission: permission,
        expiresAt: expiresAt,
        maxDownloads: maxDownloads,
      );

      // BR-16/17: Audit log
      await _audit.log(
        action: 'share.create.link',
        metadata: {
          'share_id': share.id,
          'file_id': file.id,
          'file_name': file.name,
          'permission': permission,
          'expires_at': expiresAt?.toIso8601String(),
        },
      );

      state = const SharingState(isLoading: false);
      _ref.invalidate(fileSharesProvider(file.id));
      _ref.invalidate(ownerSharesProvider);

      return 'https://privault.app/s/${share.id}#key=$linkKey';
    } catch (e) {
      state = SharingState(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Share with user by email (BR-13) + audit log
  Future<void> shareWithUser({
    required FileMetadata file,
    required String email,
    String permission = 'view',
    DateTime? expiresAt,
  }) async {
    state = const SharingState(isLoading: true);
    try {
      final vault = _ref.read(vaultServiceProvider);
      final repo = _ref.read(shareRepositoryProvider);

      final seed = await vault.getMasterKeySeed();
      if (seed == null) throw Exception('No master key found');
      final masterKey = CryptoUtils.fromBase64(seed);

      final privKeyB64 = await vault.getSharingPrivateKey();
      if (privKeyB64 == null) throw Exception('Sharing keys not found');
      final senderPrivateKey = CryptoUtils.fromBase64(privKeyB64);

      await repo.shareWithUser(
        file: file,
        masterKey: masterKey,
        senderPrivateKey: senderPrivateKey,
        recipientEmail: email,
        permission: permission,
        expiresAt: expiresAt,
      );

      // BR-16/17: Audit log
      await _audit.log(
        action: 'share.create.user',
        metadata: {
          'file_id': file.id,
          'file_name': file.name,
          'recipient_email': email,
          'permission': permission,
          'expires_at': expiresAt?.toIso8601String(),
        },
      );
      final user = FirebaseAuth.instance.currentUser;
      await _notifications.notifyFileEvent(
        recipientEmail: email,
        type: 'file_shared_with_user',
        fileId: file.id,
        fileName: file.name,
        actorId: user?.uid ?? '',
        actorName: user?.email ?? 'User',
      );

      state = const SharingState(isLoading: false);
      _ref.invalidate(fileSharesProvider(file.id));
      _ref.invalidate(ownerSharesProvider);
    } catch (e) {
      state = SharingState(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Share with team (BR-13) + audit log
  Future<void> shareWithTeam({
    required FileMetadata file,
    required String teamId,
    String permission = 'view',
    DateTime? expiresAt,
  }) async {
    state = const SharingState(isLoading: true);
    try {
      final repo = _ref.read(shareRepositoryProvider);

      await repo.shareWithTeam(
        fileId: file.id,
        fileName: file.name,
        teamId: teamId,
        permission: permission,
        expiresAt: expiresAt,
      );

      // BR-16/17: Audit log
      await _audit.log(
        action: 'share.create.team',
        metadata: {
          'file_id': file.id,
          'file_name': file.name,
          'team_id': teamId,
          'permission': permission,
        },
      );

      state = const SharingState(isLoading: false);
      _ref.invalidate(fileSharesProvider(file.id));
      _ref.invalidate(ownerSharesProvider);
    } catch (e) {
      state = SharingState(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<String> createTeam(String name) async {
    final repo = _ref.read(shareRepositoryProvider);
    return repo.createTeam(name: name);
  }

  Future<void> addTeamMember({
    required String teamId,
    required String memberIdentifier,
  }) async {
    final repo = _ref.read(shareRepositoryProvider);
    await repo.addTeamMember(teamId: teamId, memberIdentifier: memberIdentifier);
    _ref.invalidate(myTeamsProvider);
  }

  /// Revoke a share (BR-15) + audit log
  Future<void> revokeShare(String fileId, String shareId) async {
    state = const SharingState(isLoading: true);
    try {
      final repo = _ref.read(shareRepositoryProvider);
      await repo.revokeShare(shareId);

      // BR-16/17: Audit log
      await _audit.log(
        action: 'share.revoke',
        metadata: {'share_id': shareId, 'file_id': fileId},
      );

      state = const SharingState(isLoading: false);
      _ref.invalidate(fileSharesProvider(fileId));
      _ref.invalidate(ownerSharesProvider);
    } catch (e) {
      state = SharingState(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final sharingProvider =
    StateNotifierProvider<SharingNotifier, SharingState>((ref) {
  return SharingNotifier(ref);
});

// ── Helpers ───────────────────────────────────────────────────

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