// ============================================================
// PriVault – Settings Screen
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/core/router/app_router.dart';
import 'package:pri_vault/features/auth/providers/auth_provider.dart';
import 'package:pri_vault/features/auth/providers/profile_provider.dart';
import 'package:pri_vault/features/files/providers/files_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final storageAsync = ref.watch(storageUsageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Profile section
          profileAsync.when(
            loading: () => const ListTile(
              leading: CircleAvatar(child: CircularProgressIndicator(strokeWidth: 2)),
              title: Text('Loading...'),
            ),
            error: (_, __) => const ListTile(title: Text('Could not load profile')),
            data: (profile) {
              if (profile == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: PriVaultColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PriVaultColors.divider),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: PriVaultColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        (profile['email'] as String? ?? '?')[0].toUpperCase(),
                        style: const TextStyle(fontSize: 24, color: PriVaultColors.primary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile['display_name'] ?? profile['email'] ?? 'User',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(profile['email'] ?? '',
                              style: const TextStyle(color: PriVaultColors.textSecondary, fontSize: 13)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: PriVaultColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              (profile['account_type'] as String? ?? 'regular').toUpperCase(),
                              style: const TextStyle(fontSize: 10, color: PriVaultColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Storage usage
          storageAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (usage) {
              final usedPct = double.tryParse(usage['used_percent']?.toString() ?? '0') ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PriVaultColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Storage', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('${usedPct.toStringAsFixed(1)}%', style: const TextStyle(color: PriVaultColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: usedPct / 100,
                          minHeight: 6,
                          backgroundColor: PriVaultColors.divider,
                          color: usedPct < 70 ? PriVaultColors.primary : usedPct < 90 ? Colors.amber : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          const Divider(indent: 16, endIndent: 16),

          // Settings items
          _SettingsTile(
            icon: Icons.security_rounded,
            title: 'Security & Privacy',
            subtitle: '2FA, biometrics',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            subtitle: 'Manage alerts',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'About PriVault',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),

          const Divider(indent: 16, endIndent: 16),

          // Sign out
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authStateProvider.notifier).signOut();
                if (context.mounted) context.go(AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: PriVaultColors.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(color: PriVaultColors.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: PriVaultColors.textSecondary),
      onTap: onTap,
    );
  }
}
