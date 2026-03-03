// ============================================================
// PriVault – Animated List Item
// ============================================================
// Stagger-animated list item with fade + slide.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// An animated list item that fades and slides in with stagger delay.
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  final Duration duration;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.baseDelay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: baseDelay * index)
        .fadeIn(duration: duration)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }
}
