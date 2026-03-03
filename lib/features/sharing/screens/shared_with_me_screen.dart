// ============================================================
// PriVault – Shared With Me Screen
// ============================================================
// Displays files that other users have shared with the current
// user via public key cryptography.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/features/sharing/providers/sharing_provider.dart';
import 'package:pri_vault/features/files/screens/file_detail_screen.dart';

class SharedWithMeScreen extends ConsumerWidget {
  const SharedWithMeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedFilesAsync = ref.watch(sharedWithMeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared With Me'),
      ),
      body: sharedFilesAsync.when(
        data: (sharedFiles) {
          if (sharedFiles.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            itemCount: sharedFiles.length,
            itemBuilder: (context, index) {
              final shared = sharedFiles[index];
              return ListTile(
                leading: const Icon(
                  Icons.insert_drive_file_rounded,
                  color: PriVaultColors.primary,
                ),
                title: Text(
                  'Encrypted File', // Filename is encrypted too
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Shared by ${shared.parentShare.ownerId.substring(0, 8)}...',
                  style: const TextStyle(color: PriVaultColors.textSecondary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FileViewerScreen(
                        file: shared.file,
                        displayName: 'Shared File',
                        sharedFile: shared, // New parameter
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: $err'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_alt_rounded,
            size: 80,
            color: PriVaultColors.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Shared Files Yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Files others share with you will appear here.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PriVaultColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
