// ============================================================
// PriVault – GoRouter Configuration
// ============================================================
// All routes wired to real feature screens.
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/features/auth/providers/auth_provider.dart';
import 'package:pri_vault/ui/widgets/bottom_nav.dart';

// Auth screens
import 'package:pri_vault/features/auth/screens/login_screen.dart';
import 'package:pri_vault/features/auth/screens/signup_screen.dart';
import 'package:pri_vault/features/auth/screens/forgot_password_screen.dart';
import 'package:pri_vault/features/auth/screens/reset_password_screen.dart';

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

// Route path constants.
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String signup = '/signup';
  static const String twoFactor = '/two-factor';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
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
}

// Navigator keys for shell routes.
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,

    redirect: (context, state) async {
      final api = ref.read(apiClientProvider);
      final token = await api.getToken();
      final isLoggedIn = token != null;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.twoFactor ||
          state.matchedLocation == AppRoutes.forgotPassword ||
          state.matchedLocation == AppRoutes.resetPassword;

      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
      if (isLoggedIn && isAuthRoute) return AppRoutes.home;
      return null;
    },

    routes: [
      // --- Auth Routes ---
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.signup, builder: (_, __) => const SignupScreen()),
      GoRoute(path: AppRoutes.twoFactor, builder: (_, __) => const _TwoFactorScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (_, state) {
          final email = state.extra as String? ?? '';
          return ResetPasswordScreen(email: email);
        },
      ),

      // --- Main Shell with Bottom Navigation ---
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => PriVaultShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, pageBuilder: (_, __) => const NoTransitionPage(child: DashboardScreen())),
          GoRoute(path: AppRoutes.files, pageBuilder: (_, __) => const NoTransitionPage(child: FilesScreen())),
          GoRoute(path: AppRoutes.sharing, pageBuilder: (_, __) => const NoTransitionPage(child: SharingScreen())),
          GoRoute(path: AppRoutes.more, pageBuilder: (_, __) => const NoTransitionPage(child: _MoreScreen())),
        ],
      ),

      // --- Full-screen feature routes ---
      GoRoute(path: AppRoutes.secureVault, builder: (_, __) => const SecureVaultScreen()),
      GoRoute(path: AppRoutes.company, builder: (_, __) => const CompanyScreen()),
      GoRoute(path: AppRoutes.papersWallet, builder: (_, __) => const PapersWalletScreen()),
      GoRoute(path: AppRoutes.camscanner, builder: (_, __) => const CamScannerScreen()),
      GoRoute(path: AppRoutes.auditLogs, builder: (_, __) => const AuditLogsScreen()),
      GoRoute(path: AppRoutes.trash, builder: (_, __) => const TrashScreen()),
      GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
    ],
  );
});

// --- 2FA Verification Screen ---

class _TwoFactorScreen extends ConsumerWidget {
  const _TwoFactorScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Identity')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user_rounded, size: 64, color: Colors.amber),
            const SizedBox(height: 24),
            const Text('Enter the verification code sent to your email',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 24),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, letterSpacing: 8),
              decoration: const InputDecoration(hintText: '000000', counterText: ''),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).verify2FA(code: codeCtrl.text.trim());
                final state = ref.read(authStateProvider);
                if (state.status == AuthStatus.authenticated && context.mounted) {
                  context.go(AppRoutes.home);
                }
              },
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- More Screen ---

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          _MoreTile(Icons.security_rounded, 'Secure Vault', AppRoutes.secureVault),
          _MoreTile(Icons.document_scanner_rounded, 'CamScanner', AppRoutes.camscanner),
          _MoreTile(Icons.credit_card_rounded, 'Papers Wallet', AppRoutes.papersWallet),
          _MoreTile(Icons.business_rounded, 'Company', AppRoutes.company),
          _MoreTile(Icons.history_rounded, 'Audit Logs', AppRoutes.auditLogs),
          _MoreTile(Icons.delete_outline_rounded, 'Trash', AppRoutes.trash),
          const Divider(indent: 16, endIndent: 16),
          _MoreTile(Icons.settings_rounded, 'Settings', AppRoutes.settings),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  const _MoreTile(this.icon, this.title, this.route);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(route),
    );
  }
}
