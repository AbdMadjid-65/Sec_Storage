// ============================================================
// PriVault – Floating pill bottom navigation (slim)
// ============================================================

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pri_vault/core/router/app_router.dart';
import 'package:pri_vault/core/theme/app_theme.dart';

class PriVaultShell extends ConsumerWidget {
  final Widget child;

  const PriVaultShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.files)) return 1;
    if (location.startsWith(AppRoutes.chat)) return 2;
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
        context.go(AppRoutes.chat);
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

    const barHeight = 56.0;
    const iconSize = 22.0;

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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: barHeight,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C2E).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavPillItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      isSelected: currentIndex == 0,
                      iconSize: iconSize,
                      onTap: () => _onTap(context, 0),
                    ),
                    _NavPillItem(
                      icon: Icons.folder_rounded,
                      label: 'My Files',
                      isSelected: currentIndex == 1,
                      iconSize: iconSize,
                      onTap: () => _onTap(context, 1),
                    ),
                    _NavPillItem(
                      icon: Icons.chat_bubble_rounded,
                      label: 'Chat',
                      isSelected: currentIndex == 2,
                      iconSize: iconSize,
                      onTap: () => _onTap(context, 2),
                    ),
                    _NavPillItem(
                      icon: Icons.shield_rounded,
                      label: 'Vault',
                      isSelected: currentIndex == 3,
                      iconSize: iconSize,
                      onTap: () => _onTap(context, 3),
                    ),
                    _NavPillItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      isSelected: currentIndex == 4,
                      iconSize: iconSize,
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

class _NavPillItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final double iconSize;
  final VoidCallback onTap;

  const _NavPillItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 12 : 8,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: iconSize,
                    color: isSelected
                        ? Colors.white
                        : PriVaultColors.textSecondary.withValues(alpha: 0.85),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
