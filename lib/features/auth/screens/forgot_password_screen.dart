// ============================================================
// PriVault – Forgot Password Screen
// ============================================================
// Allows user to enter email and request an OTP reset code.
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pri_vault/core/router/app_router.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/features/auth/providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    await ref.read(authStateProvider.notifier).sendResetCode(email: email);

    if (!mounted) return;

    final authState = ref.read(authStateProvider);

    if (authState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error!),
          backgroundColor: PriVaultColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.successMessage ?? 'Reset code sent!'),
          backgroundColor: PriVaultColors.success,
        ),
      );
      // Only navigate to reset screen on success
      if (context.mounted) {
        context.go(AppRoutes.resetPassword, extra: email);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: PriVaultColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 48,
                  color: PriVaultColors.warning,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Reset Your Password',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your email and we\'ll send you a verification code',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PriVaultColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 48),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                onSubmitted: (_) => _handleSendCode(),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: isLoading ? null : _handleSendCode,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Send Reset Code'),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
