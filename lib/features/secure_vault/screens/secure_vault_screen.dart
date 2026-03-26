// ============================================================
// PriVault – Secure Vault Screen (BR-11, BR-COMP-15) – Firebase
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/ui/widgets/privault_button.dart';

import 'package:pri_vault/features/files/providers/files_provider.dart';
import 'package:pri_vault/models/file_metadata.dart';

// --- Providers ---

final vaultFilesProvider = FutureProvider<List<FileMetadata>>((ref) async {
  final repo = ref.read(storageRepositoryProvider);
  return repo.getFiles(isVault: true);
});

// --- Screen ---

class SecureVaultScreen extends ConsumerWidget {
  const SecureVaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(vaultFilesProvider);

    return Scaffold(
      backgroundColor: PriVaultColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Vault',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Your most sensitive files', style: TextStyle(color: PriVaultColors.textHint, fontSize: 14)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Vault Contents
              Expanded(
                child: filesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
                  data: (files) {
                    return Column(
                      children: [
                        // Success Message
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Vault Unlocked', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
                                    Text('Your files are now accessible', style: TextStyle(fontSize: 12, color: PriVaultColors.textHint)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Files List or Empty State
                        Expanded(
                          child: files.isEmpty
                              ? _buildEmptyState(context)
                              : ListView.separated(
                                  padding: EdgeInsets.zero,
                                  itemCount: files.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, i) {
                                    final file = files[i];

                                    return InkWell(
                                      onTap: () {}, // view/decrypt
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: PriVaultColors.surfaceLight,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: PriVaultColors.cardBorder),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: PriVaultColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: const Icon(Icons.description_rounded, color: PriVaultColors.primary, size: 24),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    file.name,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                          fontWeight: FontWeight.w500,
                                                          fontSize: 14,
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _formatBytes(file.sizeBytes),
                                                    style: const TextStyle(color: PriVaultColors.textSecondary, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.shield_rounded, color: PriVaultColors.primary, size: 20),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),

                        // Add to Vault Button
                        const SizedBox(height: 16),
                        if (files.isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () {}, // Add logic
                              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                              label: const Text('Add to Vault', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: PriVaultColors.surfaceLight,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, size: 32, color: PriVaultColors.textHint),
          ),
          const SizedBox(height: 16),
          Text('Your vault is empty', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Add sensitive files to keep them secure', style: TextStyle(color: PriVaultColors.textHint, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            child: PriVaultButton(
              text: 'Add Files',
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
}
