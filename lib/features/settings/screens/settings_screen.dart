// ============================================================
// PriVault – Settings Screen
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:pri_vault/core/router/app_router.dart';
import 'package:pri_vault/features/auth/providers/auth_provider.dart';
import 'package:pri_vault/features/auth/providers/profile_provider.dart';
import 'package:pri_vault/features/setup/widgets/plan_selection_sheet.dart';
import 'package:pri_vault/core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _pauseNotifications;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    _pauseNotifications = box.get('pauseNotifications', defaultValue: false) as bool;
  }

  void _setPause(bool v) {
    setState(() => _pauseNotifications = v);
    Hive.box('settings').put('pauseNotifications', v);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: PriVaultColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                   GestureDetector(
                     onTap: () => context.pop(),
                     child: Container(
                       width: 40,
                       height: 40,
                       decoration: BoxDecoration(
                         color: PriVaultColors.surfaceLight,
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: PriVaultColors.cardBorder),
                       ),
                       child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Text(
                       'Settings',
                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
                             fontWeight: FontWeight.w700,
                             color: Colors.white,
                           ),
                     ),
                   ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile section
                    profileAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (profile) {
                        if (profile == null) return const SizedBox.shrink();
                        final photoUrl = profile['photoUrl'] as String?;
                        final displayName = profile['display_name'] as String? ?? 'User';
                        final username = profile['display_name'] != null 
                            ? profile['display_name'].toString().replaceAll(' ', '').toLowerCase()
                            : 'user';

                        return GestureDetector(
                          onTap: () => context.push(AppRoutes.editProfile),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.indigoAccent.withValues(alpha: 0.1),
                                  Colors.cyanAccent.withValues(alpha: 0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: PriVaultColors.primaryGradient,
                                  ),
                                  child: ClipOval(
                                    child: photoUrl != null
                                        ? Image.network(photoUrl, fit: BoxFit.cover)
                                        : Center(
                                            child: Text(
                                              displayName[0].toUpperCase(),
                                              style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '@$username',
                                        style: const TextStyle(color: Colors.indigoAccent, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: PriVaultColors.textHint, size: 24),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Group 1: Notifications & General
                    _SettingsGroup(
                      children: [
                        _SettingsRow(
                          iconBox: const _IconBox(icon: Icons.notifications_off_rounded, color: Colors.indigoAccent),
                          label: 'Pause notifications',
                          trailing: CupertinoSwitch(
                            value: _pauseNotifications,
                            activeTrackColor: Colors.greenAccent.shade400,
                            onChanged: _setPause,
                          ),
                        ),
                        const _SettingsDivider(),
                        _SettingsRow(
                          iconBox: const _IconBox(icon: Icons.settings_rounded, color: Colors.purpleAccent),
                          label: 'General settings',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Group 2: Account
                    profileAsync.maybeWhen(
                      data: (profile) {
                        if (profile == null) return const SizedBox.shrink();
                        final accountType = profile['accountType'] as String? ?? profile['account_type'] as String? ?? 'personal';
                        final plan = profile['plan'] as String? ?? 'free';
                        final planLabel = plan == 'premium' ? 'Premium • 20GB'
                            : plan == 'professional' ? 'Professional • Unlimited'
                            : 'Free • 3GB';
                        
                        return Column(
                          children: [
                            _SettingsGroup(
                              children: [
                                _SettingsRow(
                                  iconBox: const _IconBox(icon: Icons.workspace_premium_rounded, color: Colors.white, isGradient: true),
                                  label: 'Upgrade Plan',
                                  subtitle: planLabel,
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => const PlanSelectionSheet(),
                                    );
                                  },
                                ),
                                if (accountType == 'personal' || accountType == 'regular') ...[
                                  const _SettingsDivider(),
                                  _SettingsRow(
                                    iconBox: const _IconBox(icon: Icons.domain_rounded, color: Colors.purpleAccent),
                                    label: 'Upgrade to Company Account',
                                    onTap: () => context.push(AppRoutes.company),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),

                    // Group 4: Support
                    _SettingsGroup(
                      children: [
                        _SettingsRow(
                          iconBox: const _IconBox(icon: Icons.help_outline_rounded, color: Colors.greenAccent),
                          label: 'FAQ',
                          onTap: () => context.push(AppRoutes.faq),
                        ),
                        const _SettingsDivider(),
                        _SettingsRow(
                          iconBox: const _IconBox(icon: Icons.description_outlined, color: Colors.orangeAccent),
                          label: 'Terms of service',
                          onTap: () {},
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Logout button fixed at bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: GestureDetector(
                onTap: () async {
                  await ref.read(authStateProvider.notifier).signOut();
                  if (context.mounted) context.go(AppRoutes.login);
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isGradient;

  const _IconBox({required this.icon, required this.color, this.isGradient = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isGradient ? null : color.withValues(alpha: 0.1),
        gradient: isGradient ? PriVaultColors.primaryGradient : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: isGradient ? Colors.white : color, size: 20),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: PriVaultColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PriVaultColors.cardBorder),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final Widget iconBox;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? subtitle;

  const _SettingsRow({
    required this.iconBox,
    required this.label,
    this.trailing,
    this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          iconBox,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: PriVaultColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) 
            trailing! 
          else 
            const Icon(Icons.chevron_right_rounded, color: PriVaultColors.textHint, size: 20),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.05),
    );
  }
}

