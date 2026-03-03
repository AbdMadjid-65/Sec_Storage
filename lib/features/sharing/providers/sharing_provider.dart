// ============================================================
// PriVault – Sharing Provider (Riverpod)
// ============================================================
// Merged: share_provider.dart + sharing_provider.dart
// Contains all sharing-related providers.
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';
import 'package:pri_vault/core/encryption/encryption_service.dart';
import 'package:pri_vault/repositories/share_repository.dart';
import 'package:pri_vault/models/file_metadata.dart';
import 'package:pri_vault/models/share_models.dart';
import 'package:pri_vault/services/vault_service.dart';

// ── Repository Provider ──────────────────────────────────────

/// Share Repository provider.
final shareRepositoryProvider = Provider<ShareRepository>((ref) {
  final api = ref.read(apiClientProvider);
  final encryption = EncryptionService();
  return ShareRepository(api, encryption);
});

// ── VaultService Provider ────────────────────────────────────

/// VaultService provider — used across files, trash, search, vault screens.
final vaultServiceProvider = Provider<VaultService>((ref) {
  return VaultService();
});

// ── Data Providers ───────────────────────────────────────────

/// Shares for a specific file.
final fileSharesProvider = FutureProvider.family<List<Share>, String>((ref, fileId) async {
  final repo = ref.read(shareRepositoryProvider);
  return repo.getSharesForFile(fileId);
});

/// Files shared with the current user.
final sharedWithMeProvider = FutureProvider<List<SharedFile>>((ref) async {
  final repo = ref.read(shareRepositoryProvider);
  return repo.getSharedWithMe();
});

/// All shares owned by the current user (with file metadata).
final ownerSharesProvider = FutureProvider<List<(Share, FileMetadata?)>>((ref) async {
  final api = ref.read(apiClientProvider);
  final raw = await api.getList('/shares/mine');
  return raw.map((item) {
    final map = item as Map<String, dynamic>;
    final share = Share.fromJson(map);
    FileMetadata? file;
    try {
      // The /shares/mine endpoint joins file metadata
      if (map['encrypted_name'] != null) {
        file = FileMetadata.fromJson(map);
      }
    } catch (_) {
      file = null;
    }
    return (share, file);
  }).toList();
});

/// All shares owned by the current user (flat list).
final mySharesProvider = FutureProvider<List<Share>>((ref) async {
  final repo = ref.read(shareRepositoryProvider);
  return repo.getOwnerShares();
});

// ── Sharing Notifier ─────────────────────────────────────────

class SharingState {
  final bool isLoading;
  final String? error;
  const SharingState({this.isLoading = false, this.error});
}

class SharingNotifier extends StateNotifier<SharingState> {
  final Ref _ref;

  SharingNotifier(this._ref) : super(const SharingState());

  /// Create a public link for a file (BR-13)
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

      state = const SharingState(isLoading: false);
      _ref.invalidate(fileSharesProvider(file.id));

      return 'https://privault.app/s/${share.id}#key=$linkKey';
    } catch (e) {
      state = SharingState(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Share a file with another user via email (BR-13)
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

      state = const SharingState(isLoading: false);
      _ref.invalidate(fileSharesProvider(file.id));
    } catch (e) {
      state = SharingState(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Share with team (BR-13)
  Future<void> shareWithTeam({
    required String fileId,
    required String teamId,
    String permission = 'view',
    DateTime? expiresAt,
  }) async {
    state = const SharingState(isLoading: true);
    try {
      final repo = _ref.read(shareRepositoryProvider);
      await repo.shareWithTeam(
        fileId: fileId,
        teamId: teamId,
        permission: permission,
        expiresAt: expiresAt,
      );
      state = const SharingState(isLoading: false);
      _ref.invalidate(fileSharesProvider(fileId));
    } catch (e) {
      state = SharingState(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Revoke a share (BR-15)
  Future<void> revokeShare(String fileId, String shareId) async {
    state = const SharingState(isLoading: true);
    try {
      final repo = _ref.read(shareRepositoryProvider);
      await repo.revokeShare(shareId);
      state = const SharingState(isLoading: false);
      _ref.invalidate(fileSharesProvider(fileId));
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
