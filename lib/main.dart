// ============================================================
// PriVault – App Entry Point
// ============================================================
// Initializes Firebase, Hive, and wraps the app with Riverpod
// ProviderScope, GoRouter, and the PriVault dark theme.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:pri_vault/firebase_options.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/core/router/app_router.dart';
import 'package:pri_vault/features/notifications/notification_bootstrap.dart';
import 'package:pri_vault/services/notification_service.dart';

Future<void> main() async {
  try {
    // Ensure Flutter bindings are initialized.
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase. The Google Services Gradle plugin may have
    // already auto-initialised the [DEFAULT] app at the native layer,
    // so we catch and ignore the duplicate-app error.
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
    }

    // Force dark system UI overlay.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: PriVaultColors.surface,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Preferred orientations (portrait-first).
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize Hive for encrypted local caching.
    await Hive.initFlutter();
    await Hive.openBox('settings');

    await NotificationService.initLocalNotifications();

    // Run the app wrapped in Riverpod ProviderScope.
    runApp(const ProviderScope(child: PriVaultApp()));
  } catch (e, stack) {
    // ignore: avoid_print
    print('❌ FATAL APP STARTUP ERROR: $e');
    // ignore: avoid_print
    print(stack);

    // Fallback UI to show the error if everything else fails
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child:
                  Text('Fatal Error: $e\n\nPlease check your configuration.'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Root application widget.
class PriVaultApp extends ConsumerWidget {
  const PriVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'PriVault',
      debugShowCheckedModeBanner: false,

      // Dark-first Material 3 theme.
      theme: buildPriVaultTheme(),

      // GoRouter configuration.
      routerConfig: router,

      builder: (context, child) {
        // Wrap with global error boundary.
        return MediaQuery(
          // Prevent system font scaling from breaking layouts.
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: NotificationBootstrap(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
