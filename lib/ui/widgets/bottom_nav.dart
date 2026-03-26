// ============================================================
// PriVault – Custom Animated Bottom Navigation Shell
// ============================================================

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pri_vault/core/router/app_router.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/features/auth/providers/profile_provider.dart';

class PriVaultShell extends ConsumerWidget {
  final Widget child;

  const PriVaultShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.files)) return 1;
    if (location.startsWith(AppRoutes.sharing)) return 2;
    if (location.startsWith(AppRoutes.secureVault)) return 3;
    if (location.startsWith(AppRoutes.settings)) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.files);
        break;
      case 2:
        context.go(AppRoutes.sharing);
        break;
      case 3:
        context.go(AppRoutes.secureVault);
        break;
      case 4:
        context.go(AppRoutes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _currentIndex(context);
    final location = GoRouterState.of(context).matchedLocation;

    // Watch Firestore profile stream for the profile photo.
    final profileAsync = ref.watch(userProfileProvider);
    final photoUrl = profileAsync.valueOrNull?['photoUrl'] as String?;

    return Scaffold(
      extendBody: true,
      backgroundColor: PriVaultColors.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(location),
          child: child,
        ),
      ),
      // Floating Bottom Nav with animated items
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A24).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      isSelected: currentIndex == 0,
                      onTap: () => _onTap(context, 0),
                    ),
                    _NavItem(
                      icon: Icons.folder_outlined,
                      activeIcon: Icons.folder_rounded,
                      label: 'Files',
                      isSelected: currentIndex == 1,
                      onTap: () => _onTap(context, 1),
                    ),
                    _NavItem(
                      icon: Icons.share_outlined,
                      activeIcon: Icons.share_rounded,
                      label: 'Shared',
                      isSelected: currentIndex == 2,
                      onTap: () => _onTap(context, 2),
                    ),
                    _NavItem(
                      icon: Icons.shield_outlined,
                      activeIcon: Icons.shield_rounded,
                      label: 'Vault',
                      isSelected: currentIndex == 3,
                      onTap: () => _onTap(context, 3),
                    ),
                    // Profile tab — shows CircleAvatar with photo from Firestore stream.
                    _ProfileNavItem(
                      photoUrl: photoUrl,
                      label: 'Profile',
                      isSelected: currentIndex == 4,
                      onTap: () => _onTap(context, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minWidth: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: isSelected ? PriVaultColors.primaryGradient : null,
                color: isSelected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: PriVaultColors.primary.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? Colors.white : PriVaultColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : PriVaultColors.textHint,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile tab nav item that shows the user's photo from Firestore stream.
/// Uses [ValueKey] to force a rebuild whenever the photo URL changes.
class _ProfileNavItem extends StatelessWidget {
  final String? photoUrl;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfileNavItem({
    required this.photoUrl,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minWidth: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: isSelected ? PriVaultColors.primaryGradient : null,
                color: isSelected ? null : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: PriVaultColors.primary.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: CircleAvatar(
                key: ValueKey(photoUrl), // Forces rebuild when URL changes
                radius: 14,
                backgroundColor: const Color(0xFF1A1A24),
                backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                    ? NetworkImage(photoUrl!)
                    : null,
                child: (photoUrl == null || photoUrl!.isEmpty)
                    ? Icon(
                        isSelected ? Icons.person_rounded : Icons.person_outline_rounded,
                        color: isSelected ? Colors.white : PriVaultColors.textSecondary,
                        size: 16,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : PriVaultColors.textHint,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
