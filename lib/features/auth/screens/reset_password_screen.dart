// ============================================================
// PriVault – Reset Password Screen
// ============================================================
// User enters OTP + new password to complete password reset.
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pri_vault/core/router/app_router.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/features/auth/providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _codeVerified = false;

  // Resend cooldown
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendCooldown = 0);
      } else {
        if (mounted) setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _handleResendCode() async {
    _startCooldown();
    await ref
        .read(authStateProvider.notifier)
        .sendResetCode(email: widget.email);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A new code has been sent to your email'),
        backgroundColor: PriVaultColors.success,
      ),
    );
  }

  Future<void> _handleVerifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || code.length < 6) return;

    await ref.read(authStateProvider.notifier).verifyResetCode(
          email: widget.email,
          code: code,
        );

    if (!mounted) return;

    final authState = ref.read(authStateProvider);

    if (authState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error!),
          backgroundColor: PriVaultColors.error,
        ),
      );
    } else if (authState.resetToken != null) {
      setState(() => _codeVerified = true);
    }
  }

  Future<void> _handleResetPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty) return;
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: PriVaultColors.error,
        ),
      );
      return;
    }

    await ref.read(authStateProvider.notifier).resetPassword(
          newPassword: password,
        );

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
          content:
              Text(authState.successMessage ?? 'Password reset successfully!'),
          backgroundColor: PriVaultColors.success,
        ),
      );
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.forgotPassword),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _codeVerified
                      ? PriVaultColors.success.withValues(alpha: 0.1)
                      : PriVaultColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _codeVerified
                      ? Icons.lock_open_rounded
                      : Icons.pin_rounded,
                  size: 48,
                  color: _codeVerified
                      ? PriVaultColors.success
                      : PriVaultColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                _codeVerified ? 'Set New Password' : 'Enter Verification Code',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                _codeVerified
                    ? 'Create a strong new password for your vault'
                    : 'A 6-digit code was sent to ${widget.email}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PriVaultColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 40),

              if (!_codeVerified) ...[
                // --- Code Entry ---
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, letterSpacing: 8),
                  decoration: const InputDecoration(
                    hintText: '000000',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: isLoading ? null : _handleVerifyCode,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Verify Code'),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: _resendCooldown > 0 ? null : _handleResendCode,
                  child: Text(
                    _resendCooldown > 0
                        ? 'Resend Code (${_resendCooldown}s)'
                        : 'Resend Code',
                  ),
                ),
              ] else ...[
                // --- New Password Entry ---
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Min 10 chars • uppercase • lowercase • number • special char',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PriVaultColors.textHint,
                      ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: isLoading ? null : _handleResetPassword,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Reset Password'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
