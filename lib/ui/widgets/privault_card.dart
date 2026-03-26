import 'package:flutter/material.dart';
import 'package:pri_vault/core/theme/app_theme.dart';

class PriVaultCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const PriVaultCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: PriVaultColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PriVaultColors.cardBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          hoverColor: PriVaultColors.surfaceLight.withValues(alpha: 0.5),
          highlightColor: PriVaultColors.surfaceLight.withValues(alpha: 0.5),
          splashColor: PriVaultColors.primary.withValues(alpha: 0.1),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}
