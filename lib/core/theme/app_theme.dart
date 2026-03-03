// ============================================================
// PriVault – Dark-First Material 3 Theme
// ============================================================
// Design system inspired by Proton, Bitwarden, and banking apps.
// Colors: #0F172A background, #1E293B surface, #14B8A6 primary.
// Typography: Inter font family.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PriVault color palette.
class PriVaultColors {
  PriVaultColors._();

  // --- Core ---
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceLight = Color(0xFF334155);
  static const Color primary = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0D9488);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFF06B6D4);

  // --- Text ---
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textHint = Color(0xFF64748B);

  // --- Status ---
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // --- Misc ---
  static const Color divider = Color(0xFF334155);
  static const Color cardBorder = Color(0xFF475569);
  static const Color shimmer = Color(0xFF1E293B);
  static const Color overlay = Color(0x800F172A);
}

/// PriVault text theme using Inter font.
TextTheme _buildTextTheme() {
  return GoogleFonts.interTextTheme(
    const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: PriVaultColors.textPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: PriVaultColors.textPrimary,
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: PriVaultColors.textPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: PriVaultColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: PriVaultColors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: PriVaultColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: PriVaultColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: PriVaultColors.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: PriVaultColors.textSecondary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: PriVaultColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: PriVaultColors.textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: PriVaultColors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: PriVaultColors.textPrimary,
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: PriVaultColors.textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: PriVaultColors.textHint,
        letterSpacing: 0.5,
      ),
    ),
  );
}

/// Builds the dark-first PriVault Material 3 theme.
ThemeData buildPriVaultTheme() {
  final textTheme = _buildTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: PriVaultColors.primary,
      onPrimary: PriVaultColors.background,
      secondary: PriVaultColors.secondary,
      onSecondary: Colors.white,
      surface: PriVaultColors.surface,
      onSurface: PriVaultColors.textPrimary,
      error: PriVaultColors.error,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: PriVaultColors.background,
    textTheme: textTheme,

    // --- AppBar ---
    appBarTheme: AppBarTheme(
      backgroundColor: PriVaultColors.background,
      foregroundColor: PriVaultColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.headlineSmall,
    ),

    // --- Cards ---
    cardTheme: CardThemeData(
      color: PriVaultColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: PriVaultColors.divider, width: 0.5),
      ),
    ),

    // --- Elevated Button ---
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PriVaultColors.primary,
        foregroundColor: PriVaultColors.background,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    // --- Outlined Button ---
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PriVaultColors.primary,
        minimumSize: const Size(double.infinity, 52),
        side: const BorderSide(color: PriVaultColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    // --- Text Button ---
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: PriVaultColors.primary),
    ),

    // --- Input Decoration ---
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PriVaultColors.surface,
      hintStyle: const TextStyle(color: PriVaultColors.textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PriVaultColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PriVaultColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PriVaultColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PriVaultColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PriVaultColors.error, width: 1.5),
      ),
    ),

    // --- Bottom Navigation Bar ---
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: PriVaultColors.surface,
      selectedItemColor: PriVaultColors.primary,
      unselectedItemColor: PriVaultColors.textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // --- Navigation Bar (Material 3) ---
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: PriVaultColors.surface,
      indicatorColor: PriVaultColors.primary.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: PriVaultColors.primary,
          );
        }
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: PriVaultColors.textHint,
        );
      }),
    ),

    // --- Floating Action Button ---
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: PriVaultColors.primary,
      foregroundColor: PriVaultColors.background,
    ),

    // --- Dialog ---
    dialogTheme: DialogThemeData(
      backgroundColor: PriVaultColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // --- Bottom Sheet ---
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: PriVaultColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // --- Snackbar ---
    snackBarTheme: SnackBarThemeData(
      backgroundColor: PriVaultColors.surfaceLight,
      contentTextStyle: const TextStyle(color: PriVaultColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),

    // --- Divider ---
    dividerTheme: const DividerThemeData(
      color: PriVaultColors.divider,
      thickness: 0.5,
    ),

    // --- Chip ---
    chipTheme: ChipThemeData(
      backgroundColor: PriVaultColors.surface,
      selectedColor: PriVaultColors.primary.withValues(alpha: 0.2),
      labelStyle: const TextStyle(color: PriVaultColors.textPrimary),
      side: const BorderSide(color: PriVaultColors.divider),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    // --- Progress Indicator ---
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: PriVaultColors.primary,
      linearTrackColor: PriVaultColors.surface,
    ),

    // --- Switch ---
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return PriVaultColors.primary;
        }
        return PriVaultColors.textHint;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return PriVaultColors.primary.withValues(alpha: 0.3);
        }
        return PriVaultColors.surfaceLight;
      }),
    ),

    // --- List Tile ---
    listTileTheme: const ListTileThemeData(
      iconColor: PriVaultColors.textSecondary,
      textColor: PriVaultColors.textPrimary,
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),

    // --- Tab Bar ---
    tabBarTheme: const TabBarThemeData(
      labelColor: PriVaultColors.primary,
      unselectedLabelColor: PriVaultColors.textHint,
      indicatorColor: PriVaultColors.primary,
    ),

    // --- Tooltip ---
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: PriVaultColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: PriVaultColors.textPrimary,
        fontSize: 12,
      ),
    ),
  );
}
