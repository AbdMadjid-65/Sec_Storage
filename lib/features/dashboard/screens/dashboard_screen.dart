// ============================================================
// PriVault – Dashboard Screen (BR-25)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/core/router/app_router.dart';
import 'package:pri_vault/features/auth/providers/auth_provider.dart';

// --- Providers ---

final dashboardStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  return await api.get('/dashboard/stats');
});

final dashboardActivityProvider =
    FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  return await api.getList('/dashboard/activity');
});

// --- Screen ---

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authStateProvider.notifier).signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(dashboardActivityProvider);
        },
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(error: e.toString(), onRetry: () => ref.invalidate(dashboardStatsProvider)),
          data: (stats) => _DashboardContent(stats: stats),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _DashboardContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    final storage = stats['storage'] as Map<String, dynamic>? ?? {};
    final usedBytes = (storage['storage_used_bytes'] ?? 0) as num;
    final maxBytes = (storage['storage_max_bytes'] ?? 3221225472) as num;
    final usedPercent = maxBytes > 0 ? (usedBytes / maxBytes) : 0.0;
    final totalFiles = stats['total_files'] ?? 0;
    final sharedFiles = stats['shared_files'] ?? 0;
    final trashFiles = stats['trash_files'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Storage Card ---
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_rounded, color: PriVaultColors.primary),
                  const SizedBox(width: 8),
                  Text('Storage', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: usedPercent.toDouble(),
                  minHeight: 10,
                  backgroundColor: PriVaultColors.divider,
                  color: usedPercent < 0.7
                      ? PriVaultColors.primary
                      : usedPercent < 0.9
                          ? Colors.amber
                          : Colors.redAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_formatBytes(usedBytes.toInt())} of ${_formatBytes(maxBytes.toInt())} used',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: PriVaultColors.textSecondary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // --- Quick Stats ---
        Row(
          children: [
            Expanded(child: _StatTile(icon: Icons.folder_rounded, label: 'Files', value: '$totalFiles', color: PriVaultColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: _StatTile(icon: Icons.share_rounded, label: 'Shared', value: '$sharedFiles', color: Colors.teal)),
            const SizedBox(width: 12),
            Expanded(child: _StatTile(icon: Icons.delete_outline_rounded, label: 'Trash', value: '$trashFiles', color: Colors.orange)),
          ],
        ),

        const SizedBox(height: 20),

        // --- Quick Actions ---
        Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _QuickAction(icon: Icons.upload_file_rounded, label: 'Upload', onTap: () => context.go(AppRoutes.files)),
            _QuickAction(icon: Icons.document_scanner_rounded, label: 'Scan', onTap: () => context.push(AppRoutes.camscanner)),
            _QuickAction(icon: Icons.security_rounded, label: 'Vault', onTap: () => context.push(AppRoutes.secureVault)),
            _QuickAction(icon: Icons.credit_card_rounded, label: 'Wallet', onTap: () => context.push(AppRoutes.papersWallet)),
          ],
        ),

        const SizedBox(height: 20),

        // --- Top Files ---
        if ((stats['top_files'] as List?)?.isNotEmpty == true) ...[
          Text('Most Accessed', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...(stats['top_files'] as List).take(5).map((f) {
            final fMap = f as Map<String, dynamic>;
            return ListTile(
              dense: true,
              leading: const Icon(Icons.insert_drive_file_rounded, size: 20),
              title: Text(fMap['encrypted_name'] ?? 'Encrypted file', maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text('${fMap['access_count']}×', style: const TextStyle(color: PriVaultColors.textSecondary)),
            );
          }),
        ],
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PriVaultColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PriVaultColors.divider),
      ),
      child: child,
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatTile({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold)),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: PriVaultColors.textSecondary)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: PriVaultColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PriVaultColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: PriVaultColors.primary),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center, style: const TextStyle(color: PriVaultColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
