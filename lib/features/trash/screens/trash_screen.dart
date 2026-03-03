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
import 'package:pri_vault/features/auth/providers/auth_provider.dart';
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
        title: const Text('Trash'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded),
            tooltip: 'Empty Trash',
            onPressed: () => _handleEmptyTrash(context, ref),
          ),
        ],
      ),
      body: trashAsync.when(
        data: (files) {
          if (files.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 80,
                    color: PriVaultColors.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Trash is empty',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deleted files appear here for 30 days',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: PriVaultColors.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(deletedFilesProvider),
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) =>
                  _TrashFileTile(file: files[index]),
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
        return ListTile(
          leading: const Icon(
            Icons.insert_drive_file_rounded,
            color: Colors.grey,
          ),
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'Deleted ${_timeAgo(file.deletedAt)} · '
            '${(file.sizeBytes / 1024).toStringAsFixed(1)} KB',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.restore_rounded),
                tooltip: 'Restore',
                onPressed: () => _handleRestore(context, ref),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.redAccent,
                ),
                tooltip: 'Delete permanently',
                onPressed: () => _handlePermanentDelete(context, ref, name),
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
