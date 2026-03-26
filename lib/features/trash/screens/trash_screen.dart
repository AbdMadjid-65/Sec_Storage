// ============================================================
// PriVault – Trash Screen (Recycle Bin)
// ============================================================
// Shows soft-deleted files with restore/permanent-delete actions.
// Files older than 30 days are flagged for auto-purge.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';

import 'package:pri_vault/features/files/providers/files_provider.dart';
import 'package:pri_vault/features/sharing/providers/sharing_provider.dart';
import 'package:pri_vault/models/file_metadata.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashAsync = ref.watch(deletedFilesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Trash',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Empty Trash',
            onPressed: () => _handleEmptyTrash(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: trashAsync.when(
        data: (files) {
          if (files.isEmpty) {
            return Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: PriVaultColors.surfaceLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: PriVaultColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.delete_outline_rounded, size: 48, color: PriVaultColors.primary.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 16),
                    Text('Trash is Empty', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('Deleted files appear here for 30 days before being permanently removed.', style: TextStyle(color: PriVaultColors.textHint), textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(deletedFilesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: files.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _TrashFileTile(file: files[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _handleEmptyTrash(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'Permanently delete all files in trash? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(storageRepositoryProvider);
        final files = ref.read(deletedFilesProvider).valueOrNull ?? [];
        for (final file in files) {
          await repo.permanentlyDeleteFile(file);
        }
        ref.invalidate(deletedFilesProvider);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trash emptied')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _TrashFileTile extends ConsumerWidget {
  final FileMetadata file;
  const _TrashFileTile({required this.file});

  Future<String> _getDecryptedName(WidgetRef ref) async {
    if (file.encryptedName.isEmpty) return 'Untitled File';
    try {
      final vault = ref.read(vaultServiceProvider);
      final encryption = ref.read(encryptionServiceProvider);
      final seedBase64 = await vault.getMasterKeySeed();
      if (seedBase64 == null) return 'Encrypted File';
      final masterKey = CryptoUtils.fromBase64(seedBase64);
      final decryptedBytes = await encryption.decrypt(
        ciphertext: CryptoUtils.fromBase64(file.encryptedName),
        key: masterKey,
      );
      return String.fromCharCodes(decryptedBytes);
    } catch (_) {
      return 'Encrypted File';
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: _getDecryptedName(ref),
      builder: (context, snapshot) {
        final name = snapshot.data ?? 'Decrypting...';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PriVaultColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PriVaultColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.insert_drive_file_rounded, color: PriVaultColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Deleted ${_timeAgo(file.deletedAt)} · ${(file.sizeBytes / 1024).toStringAsFixed(1)} KB',
                      style: const TextStyle(color: PriVaultColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: PriVaultColors.primary.withValues(alpha: 0.1)),
                    icon: const Icon(Icons.restore_rounded, color: PriVaultColors.primary),
                    tooltip: 'Restore',
                    onPressed: () => _handleRestore(context, ref),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.redAccent.withValues(alpha: 0.1)),
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                    tooltip: 'Delete permanently',
                    onPressed: () => _handlePermanentDelete(context, ref, name),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(storageRepositoryProvider).restoreFile(file);
      ref.invalidate(deletedFilesProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File restored')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    }
  }

  Future<void> _handlePermanentDelete(
    BuildContext context,
    WidgetRef ref,
    String displayName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: Text('Remove "$displayName" forever? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(storageRepositoryProvider).permanentlyDeleteFile(file);
        ref.invalidate(deletedFilesProvider);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }
}
