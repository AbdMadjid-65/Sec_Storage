// ============================================================
// PriVault – Glass Card Widget
// ============================================================
// Frosted glass / glassmorphism card component.
// Used across dashboard, file cards, and dialogs.
// ============================================================

import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:pri_vault/core/theme/app_theme.dart';

/// A frosted-glass card with blur, border, and gradient.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.blur = 10,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: (backgroundColor ?? PriVaultColors.surface).withValues(
                alpha: 0.6,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: PriVaultColors.divider.withValues(alpha: 0.3),
                width: 0.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
