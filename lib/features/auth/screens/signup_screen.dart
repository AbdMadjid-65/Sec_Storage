// ============================================================
// PriVault – Signup Screen
// ============================================================
// Secure account creation with BR-01 password validation,
// BR-03 account type selector, and key generation.
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pri_vault/core/router/app_router.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/core/validators/validators.dart';
import 'package:pri_vault/features/auth/providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _accountType = 'regular';
  double _pwStrength = 0.0;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {
        _pwStrength = passwordStrength(_passwordController.text);
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    final emailError = validateEmail(email);
    if (emailError != null) {
      _showError(emailError);
      return;
    }

    final pwError = validatePassword(password);
    if (pwError != null) {
      _showError(pwError);
      return;
    }

    if (password != confirm) {
      _showError('Passwords do not match');
      return;
    }

    await ref.read(authStateProvider.notifier).signUp(
          email: email,
          password: password,
          accountType: _accountType,
        );

    if (!mounted) return;

    final authState = ref.read(authStateProvider);

    if (authState.error != null) {
      _showError(authState.error!);
    } else if (authState.status == AuthStatus.authenticated) {
      context.go(AppRoutes.home);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vault created successfully! Welcome.'),
          backgroundColor: PriVaultColors.success,
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Create Your Vault',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Your master password encrypts everything locally. We never see it.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PriVaultColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),

              // Account type selector (BR-03)
              Row(
                children: [
                  Expanded(
                    child: _AccountTypeCard(
                      icon: Icons.person_rounded,
                      label: 'Personal',
                      selected: _accountType == 'regular',
                      onTap: () => setState(() => _accountType = 'regular'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AccountTypeCard(
                      icon: Icons.business_rounded,
                      label: 'Company',
                      selected: _accountType == 'company',
                      onTap: () => setState(() => _accountType = 'company'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Master Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  helperText: 'Min 10 chars: uppercase, lowercase, number, special char',
                ),
              ),
              const SizedBox(height: 8),

              // Password strength indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _pwStrength,
                  minHeight: 4,
                  backgroundColor: PriVaultColors.divider,
                  color: _pwStrength < 0.4
                      ? Colors.redAccent
                      : _pwStrength < 0.7
                          ? Colors.amber
                          : PriVaultColors.success,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _pwStrength < 0.4
                        ? 'Weak'
                        : _pwStrength < 0.7
                            ? 'Medium'
                            : 'Strong',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _pwStrength < 0.4
                              ? Colors.redAccent
                              : _pwStrength < 0.7
                                  ? Colors.amber
                                  : PriVaultColors.success,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Master Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                onSubmitted: (_) => _handleSignup(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: authState.status == AuthStatus.loading
                    ? null
                    : _handleSignup,
                child: authState.status == AuthStatus.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Vault'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AccountTypeCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? PriVaultColors.primary.withValues(alpha: 0.15)
              : PriVaultColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? PriVaultColors.primary : PriVaultColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 32,
                color: selected ? PriVaultColors.primary : Colors.white54),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: selected ? PriVaultColors.primary : Colors.white70,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
