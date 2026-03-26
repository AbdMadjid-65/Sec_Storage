// ============================================================
// PriVault – Forgot Password Screen
// ============================================================
// Sends a Firebase password reset LINK to the user's email.
// Firebase Auth handles the token, expiry, and password update.
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pri_vault/core/router/app_router.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/features/auth/providers/auth_provider.dart';
import 'package:pri_vault/ui/widgets/privault_button.dart';
import 'package:pri_vault/ui/widgets/privault_textfield.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _linkSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    final email = _emailController.text.trim();

    // Basic client-side validation before hitting Firebase
    if (email.isEmpty) {
      _showError('Please enter your email address.');
      return;
    }
    if (!RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }

    await ref.read(authStateProvider.notifier).sendResetCode(email: email);

    if (!mounted) return;

    final authState = ref.read(authStateProvider);

    if (authState.error != null) {
      _showError(authState.error!);
    } else {
      // Success — show the confirmation UI
      setState(() => _linkSent = true);
    }
  }

  Future<void> _handleResend() async {
    // Go back to the form so user can re-enter email and resend
    setState(() => _linkSent = false);

    // Small delay so the UI transition is visible before showing snackbar
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enter your email again to resend the reset link.'),
        backgroundColor: PriVaultColors.primary,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: PriVaultColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: PriVaultColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Back Button ──────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: isLoading ? null : () => context.go(AppRoutes.login),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: PriVaultColors.textHint,
                  ),
                  label: const Text(
                    'Back to login',
                    style: TextStyle(
                      color: PriVaultColors.textHint,
                      fontSize: 14,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // ── Form State ───────────────────────────────────
              if (!_linkSent) ...[
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: PriVaultColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 36,
                      color: PriVaultColors.primary,
                    ),
                  ),
                ),
                const Text(
                  'Forgot Password?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enter your email address and we\'ll send you a link to reset your password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: PriVaultColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                PriVaultTextField(
                  controller: _emailController,
                  label: 'Email',
                  hintText: 'Enter your email address',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(
                    Icons.mail_outline_rounded,
                    color: PriVaultColors.textHint,
                  ),
                  // Allow submitting via keyboard "done" button
                  onSubmitted: isLoading ? null : (_) => _handleSendResetLink(),
                ),
                const SizedBox(height: 32),

                PriVaultButton(
                  onPressed: isLoading ? null : _handleSendResetLink,
                  text: 'Send Reset Link',
                  isLoading: isLoading,
                ),
              ],

              // ── Success State ────────────────────────────────
              if (_linkSent) ...[
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: PriVaultColors.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      size: 48,
                      color: PriVaultColors.success,
                    ),
                  ),
                ),
                const Text(
                  'Check your inbox',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'We sent a password reset link to:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: PriVaultColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _emailController.text.trim(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: PriVaultColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Click the link in the email to reset your password.\nThe link expires in 1 hour.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: PriVaultColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),

                PriVaultButton(
                  onPressed: () => context.go(AppRoutes.login),
                  text: 'Back to Login',
                ),
                const SizedBox(height: 16),

                // ── Resend ───────────────────────────────────
                Center(
                  child: TextButton(
                    onPressed: _handleResend,
                    child: RichText(
                      text: const TextSpan(
                        text: 'Didn\'t receive it? ',
                        style: TextStyle(
                          color: PriVaultColors.textHint,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: 'Try again',
                            style: TextStyle(
                              color: PriVaultColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Tip box ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PriVaultColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: PriVaultColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: PriVaultColors.primary,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Check your spam or junk folder if you don\'t see the email in your inbox.',
                          style: TextStyle(
                            fontSize: 13,
                            color: PriVaultColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}