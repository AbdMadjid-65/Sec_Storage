// ============================================================
// PriVault – Material 3 dark theme
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PriVault color palette.
class PriVaultColors {
  PriVaultColors._();

  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF13131A);
  static const Color surface2 = Color(0xFF1C1C28);
  static const Color surfaceLight = Color(0xFF1C1C28);

  static const Color primary = Color(0xFF7C6FF7);
  static const Color primaryLight = Color(0xFF9D95F5);
  static const Color primaryDark = Color(0xFF5E54D6);
  static const Color secondary = Color(0xFF4ECDC4);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C6FF7), Color(0xFF4ECDC4)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF7C6FF7), Color(0xFF9D40CB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color textPrimary = Color(0xFFF0F0F8);
  static const Color textSecondary = Color(0xFF8888AA);
  static const Color textHint = Color(0xFF55556A);

  static const Color success = Color(0xFF6BCB77);
  static const Color warning = Color(0xFFFFD93D);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF7C6FF7);

  static const Color divider = Color(0xFF2A2A3A);
  static const Color cardBorder = Color(0xFF2A2A3A);
  static const Color shimmer = Color(0xFF2A2A3A);
  static const Color overlay = Color(0x99000000);
}

TextTheme _buildTextTheme() {
  return GoogleFonts.poppinsTextTheme(
    const TextTheme(
      displayLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: PriVaultColors.textPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: PriVaultColors.textPrimary,
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
        fontWeight: FontWeight.w500,
        color: PriVaultColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: PriVaultColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: PriVaultColors.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
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
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: PriVaultColors.textPrimary,
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
      onPrimary: Colors.white,
      secondary: PriVaultColors.secondary,
      onSecondary: Colors.white,
      surface: PriVaultColors.surface,
      onSurface: PriVaultColors.textPrimary,
      error: PriVaultColors.error,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: PriVaultColors.background,
    textTheme: textTheme,

    appBarTheme: AppBarTheme(
      backgroundColor: PriVaultColors.background,
      foregroundColor: PriVaultColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.headlineSmall,
    ),

    cardTheme: CardThemeData(
      color: PriVaultColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: PriVaultColors.cardBorder, width: 1),
      ),
      shadowColor: PriVaultColors.primary.withValues(alpha: 0.05),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PriVaultColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PriVaultColors.primary,
        minimumSize: const Size(double.infinity, 52),
        side: const BorderSide(color: PriVaultColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: PriVaultColors.primary),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PriVaultColors.surface2,
      hintStyle: const TextStyle(color: PriVaultColors.textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PriVaultColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PriVaultColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PriVaultColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PriVaultColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PriVaultColors.error, width: 1.5),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: PriVaultColors.surface,
      selectedItemColor: PriVaultColors.primary,
      unselectedItemColor: PriVaultColors.textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

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

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: PriVaultColors.primary,
      foregroundColor: PriVaultColors.background,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: PriVaultColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: PriVaultColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: PriVaultColors.surface2,
      contentTextStyle: const TextStyle(color: PriVaultColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),

    dividerTheme: const DividerThemeData(
      color: PriVaultColors.divider,
      thickness: 0.5,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: PriVaultColors.surface,
      selectedColor: PriVaultColors.primary.withValues(alpha: 0.2),
      labelStyle: const TextStyle(color: PriVaultColors.textPrimary),
      side: const BorderSide(color: PriVaultColors.cardBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: PriVaultColors.primary,
      linearTrackColor: PriVaultColors.surface,
    ),

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

    listTileTheme: const ListTileThemeData(
      iconColor: PriVaultColors.textSecondary,
      textColor: PriVaultColors.textPrimary,
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),

    tabBarTheme: const TabBarThemeData(
      labelColor: PriVaultColors.primary,
      unselectedLabelColor: PriVaultColors.textHint,
      indicatorColor: PriVaultColors.primary,
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: PriVaultColors.surface2,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: PriVaultColors.textPrimary,
        fontSize: 12,
      ),
    ),
  );
}
