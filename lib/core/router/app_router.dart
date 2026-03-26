// ============================================================
// PriVault – GoRouter Configuration
// ============================================================
// All routes wired to real feature screens.
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:pri_vault/ui/widgets/bottom_nav.dart';

import 'package:pri_vault/features/setup/screens/username_setup_screen.dart';
import 'package:pri_vault/features/setup/screens/plan_selection_screen.dart';
import 'package:pri_vault/features/setup/screens/edit_profile_screen.dart';

// Splash / Onboarding
import 'package:pri_vault/features/onboarding/screens/splash_screen.dart';
import 'package:pri_vault/features/onboarding/screens/onboarding_screen.dart';
import 'package:pri_vault/features/auth/screens/login_screen.dart';
import 'package:pri_vault/features/auth/screens/signup_screen.dart';
import 'package:pri_vault/features/auth/screens/forgot_password_screen.dart';

// Feature screens
import 'package:pri_vault/features/dashboard/screens/dashboard_screen.dart';
import 'package:pri_vault/features/files/screens/files_screen.dart';
import 'package:pri_vault/features/sharing/screens/sharing_screen.dart';
import 'package:pri_vault/features/secure_vault/screens/secure_vault_screen.dart';
import 'package:pri_vault/features/company/screens/company_screen.dart';
import 'package:pri_vault/features/papers_wallet/screens/papers_wallet_screen.dart';
import 'package:pri_vault/features/camscanner/screens/camscanner_screen.dart';
import 'package:pri_vault/features/audit/screens/audit_logs_screen.dart';
import 'package:pri_vault/features/settings/screens/settings_screen.dart';
import 'package:pri_vault/features/trash/screens/trash_screen.dart';
import 'package:pri_vault/features/notifications/screens/notifications_screen.dart';

// Route path constants.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String usernameSetup = '/username-setup';
  static const String plan = '/plan';
  static const String editProfile = '/edit-profile';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String files = '/files';
  static const String sharing = '/sharing';
  static const String more = '/more';
  static const String secureVault = '/secure-vault';
  static const String company = '/company';
  static const String papersWallet = '/papers-wallet';
  static const String camscanner = '/camscanner';
  static const String auditLogs = '/audit-logs';
  static const String settings = '/settings';
  static const String trash = '/trash';
  static const String notifications = '/notifications';
}

// Navigator keys for shell routes.
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,

    redirect: (context, state) {
      // The splash screen handles its own routing after the animation.
      if (state.matchedLocation == AppRoutes.splash) return null;

      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.forgotPassword ||
          state.matchedLocation == AppRoutes.onboarding;

      if (!isLoggedIn && !isAuthRoute) {
        final settingsBox = Hive.box('settings');
        final hasSeenOnboarding = settingsBox.get('hasSeenOnboarding', defaultValue: false);
        return hasSeenOnboarding ? AppRoutes.login : AppRoutes.onboarding;
      }
      
      if (isLoggedIn) {
        // If user has no displayName, enforce setup
        final noUsername = (user.displayName == null || user.displayName!.isEmpty);
        final isSetupRoute = state.matchedLocation == AppRoutes.usernameSetup ||
            state.matchedLocation == AppRoutes.plan;
        
        if (noUsername && !isSetupRoute) {
          return AppRoutes.usernameSetup;
        }
        
        if (!noUsername && isAuthRoute) {
           return AppRoutes.home;
        }
      }
      return null;
    },

    routes: [
      // --- Splash ---
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),

      // --- Setup / Onboarding Routes ---
      GoRoute(path: AppRoutes.usernameSetup, builder: (_, __) => const UsernameSetupScreen()),
      GoRoute(path: AppRoutes.plan, builder: (_, __) => const PlanSelectionScreen()),
      
      // --- Auth Routes ---
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.signup, builder: (_, __) => const SignupScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, __) => const ForgotPasswordScreen()),

      // --- Main Shell with Bottom Navigation ---
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => PriVaultShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, pageBuilder: (_, __) => const NoTransitionPage(child: DashboardScreen())),
          GoRoute(path: AppRoutes.files, pageBuilder: (_, __) => const NoTransitionPage(child: FilesScreen())),
          GoRoute(path: AppRoutes.sharing, pageBuilder: (_, __) => const NoTransitionPage(child: SharingScreen())),
          GoRoute(path: AppRoutes.secureVault, pageBuilder: (_, __) => const NoTransitionPage(child: SecureVaultScreen())),
        ],
      ),

      // --- Full-screen feature routes ---
      GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
      GoRoute(path: AppRoutes.company, builder: (_, __) => const CompanyScreen()),
      GoRoute(path: AppRoutes.editProfile, builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: AppRoutes.papersWallet, builder: (_, __) => const PapersWalletScreen()),
      GoRoute(path: AppRoutes.camscanner, builder: (_, __) => const CamScannerScreen()),
      GoRoute(path: AppRoutes.auditLogs, builder: (_, __) => const AuditLogsScreen()),
      GoRoute(path: AppRoutes.trash, builder: (_, __) => const TrashScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (_, __) => const NotificationsScreen()),
    ],
  );
});
