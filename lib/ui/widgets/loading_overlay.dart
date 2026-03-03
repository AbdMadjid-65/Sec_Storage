// ============================================================
// PriVault – Loading Overlay
// ============================================================
// Full-screen loading overlay with optional message.
// ============================================================

import 'package:flutter/material.dart';

import 'package:pri_vault/core/theme/app_theme.dart';

/// A full-screen semi-transparent loading overlay.
class LoadingOverlay extends StatelessWidget {
  final String? message;

  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PriVaultColors.overlay,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: PriVaultColors.primary,
              strokeWidth: 3,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PriVaultColors.textSecondary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
