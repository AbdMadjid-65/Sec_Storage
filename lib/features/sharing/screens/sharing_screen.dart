// ============================================================
// PriVault – Sharing Screen (Placeholder)
// ============================================================
// Full implementation in Phase 5.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/features/sharing/providers/sharing_provider.dart';
import 'package:pri_vault/features/sharing/screens/shared_with_me_screen.dart';
import 'package:pri_vault/models/share_models.dart';

class SharingScreen extends ConsumerWidget {
  const SharingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Collab & Sharing'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Links & Shares'),
              Tab(text: 'Received'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ManagedSharesList(),
            SharedWithMeScreen(),
          ],
        ),
      ),
    );
  }
}

class _ManagedSharesList extends ConsumerWidget {
  const _ManagedSharesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharesAsync = ref.watch(ownerSharesProvider);

    return sharesAsync.when(
      data: (shares) {
        if (shares.isEmpty) {
          return const _EmptyShares();
        }

        return ListView.builder(
          itemCount: shares.length,
          itemBuilder: (context, index) {
            final (share, file) = shares[index];
            return ListTile(
              leading: Icon(
                share.type == 'link'
                    ? Icons.link_rounded
                    : Icons.people_rounded,
                color: PriVaultColors.primary,
              ),
              title: Text(
                file?.name ?? 'Deleted File',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${share.type.toUpperCase()} • ${share.isRevoked ? 'REVOKED' : 'ACTIVE'}',
                style: TextStyle(
                  color: share.isRevoked
                      ? Colors.red
                      : PriVaultColors.textSecondary,
                ),
              ),
              trailing: share.isRevoked
                  ? null
                  : IconButton(
                      icon:
                          const Icon(Icons.cancel_outlined, color: Colors.red),
                      onPressed: () => _confirmRevoke(context, ref, share),
                    ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Future<void> _confirmRevoke(
      BuildContext context, WidgetRef ref, Share share) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Access?'),
        content: const Text(
          'This will immediately disable access to this file for all recipients. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(sharingProvider.notifier).revokeShare(
            share.fileId ?? '',
            share.id,
          );
      ref.invalidate(ownerSharesProvider);
    }
  }
}

class _EmptyShares extends StatelessWidget {
  const _EmptyShares();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.share_rounded,
            size: 80,
            color: PriVaultColors.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing shared yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Create links or share with users to see them here.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PriVaultColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
