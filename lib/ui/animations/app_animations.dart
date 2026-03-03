// ============================================================
// PriVault – Common Animations
// ============================================================
// Reusable animation configurations using flutter_animate.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Common animation presets.
class AppAnimations {
  AppAnimations._();

  /// Standard fade-in duration.
  static const Duration fadeIn = Duration(milliseconds: 300);

  /// Quick transition.
  static const Duration quick = Duration(milliseconds: 150);

  /// Slow, dramatic transition.
  static const Duration slow = Duration(milliseconds: 600);

  /// Page transition duration.
  static const Duration pageTransition = Duration(milliseconds: 350);

  /// Standard curve.
  static const Curve defaultCurve = Curves.easeOutCubic;
}

/// Extension on Widget for common PriVault animations.
extension PriVaultAnimations on Widget {
  /// Fade in with subtle upward slide.
  Widget fadeInUp({Duration? delay, Duration? duration}) {
    return animate(delay: delay)
        .fadeIn(duration: duration ?? AppAnimations.fadeIn)
        .slideY(
          begin: 0.05,
          end: 0,
          duration: duration ?? AppAnimations.fadeIn,
          curve: AppAnimations.defaultCurve,
        );
  }

  /// Scale in from slightly smaller.
  Widget scaleIn({Duration? delay, Duration? duration}) {
    return animate(delay: delay)
        .fadeIn(duration: duration ?? AppAnimations.fadeIn)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: duration ?? AppAnimations.fadeIn,
          curve: AppAnimations.defaultCurve,
        );
  }
}
