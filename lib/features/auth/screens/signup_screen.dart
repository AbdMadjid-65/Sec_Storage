// ============================================================
// PriVault – Signup Screen
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:pri_vault/core/router/app_router.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/core/validators/validators.dart';
import 'package:pri_vault/features/auth/providers/auth_provider.dart';
import 'package:pri_vault/ui/widgets/privault_button.dart';
import 'package:pri_vault/ui/widgets/privault_textfield.dart';

// Reuse the Google button and divider from login_screen.dart
// (defined at the bottom of this file to keep it self-contained)

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _phoneNumber = '';
  String _detectedCountryCode = 'US'; // fallback, overridden on init

  double _pwStrength = 0.0;
  bool _has8Chars = false;
  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _detectCountry();
    _passwordController.addListener(_updatePasswordStrength);
  }

  // ── Auto-detect country from device locale ────────────────
  void _detectCountry() {
    try {
      // Platform.localeName gives e.g. "en_DZ", "fr_FR", "ar_SA"
      final locale = Platform.localeName; // e.g. "en_DZ"
      final parts = locale.split('_');
      if (parts.length >= 2) {
        final country = parts.last.toUpperCase();
        // intl_phone_field uses ISO 3166-1 alpha-2 codes
        setState(() => _detectedCountryCode = country);
      }
    } catch (_) {
      // Keep fallback 'US' if platform locale not available
    }
  }

  void _updatePasswordStrength() {
    final pw = _passwordController.text;
    setState(() {
      _has8Chars = pw.length >= 10;
      _hasUpper = pw.contains(RegExp(r'[A-Z]'));
      _hasLower = pw.contains(RegExp(r'[a-z]'));
      _hasNumber = pw.contains(RegExp(r'[0-9]'));
      _hasSymbol =
          pw.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]'));
      _pwStrength = passwordStrength(pw);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    final fn = validateRequired(firstName, 'First name');
    if (fn != null) { _showError(fn); return; }
    final ln = validateRequired(lastName, 'Last name');
    if (ln != null) { _showError(ln); return; }
    final ue = validateUsername(username);
    if (ue != null) { _showError(ue); return; }

    final emailError = validateEmail(email);
    if (emailError != null) { _showError(emailError); return; }

    final pwError = validatePassword(password);
    if (pwError != null) { _showError(pwError); return; }

    if (password != confirm) { _showError('Passwords do not match'); return; }

    if (_phoneNumber.isEmpty) {
      _showError('Phone number is required');
      return;
    }

    await ref.read(authStateProvider.notifier).signUp(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
          displayName: username,
          phoneNumber: _phoneNumber,
          accountType: 'regular',
        );

    if (!mounted) return;
    final authState = ref.read(authStateProvider);

    if (authState.error != null) {
      _showError(authState.error!);
    } else if (authState.status == AuthStatus.authenticated) {
      context.go(AppRoutes.usernameSetup);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vault created successfully! Welcome.'),
          backgroundColor: PriVaultColors.success,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    await ref.read(authStateProvider.notifier).signInWithGoogle();

    if (!mounted) return;
    final authState = ref.read(authStateProvider);

    if (authState.error != null) {
      _showError(authState.error!);
    } else if (authState.status == AuthStatus.authenticated) {
      final isNew =
          ref.read(authStateProvider.notifier).lastGoogleSignInWasNew;
      final user = authState.user;
      final hasDisplayName = user?['displayName'] != null &&
          (user!['displayName'] as String).isNotEmpty;
      if (isNew || !hasDisplayName) {
        context.go(AppRoutes.usernameSetup);
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: PriVaultColors.error,
    ),);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: PriVaultColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ───────────────────────────────────────
              const Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join PriVault today',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16, color: PriVaultColors.textSecondary,),
              ),
              const SizedBox(height: 32),

              // ── Google Sign Up ───────────────────────────────
              _GoogleSignInButton(
                label: 'Sign up with Google',
                onPressed: isLoading ? null : _handleGoogleSignIn,
              ),
              const SizedBox(height: 24),
              _OrDivider(),
              const SizedBox(height: 24),

              PriVaultTextField(
                controller: _firstNameController,
                label: 'First name',
                hintText: 'First name',
                prefixIcon: const Icon(Icons.badge_outlined, color: PriVaultColors.textHint),
              ),
              const SizedBox(height: 16),
              PriVaultTextField(
                controller: _lastNameController,
                label: 'Last name',
                hintText: 'Last name',
                prefixIcon: const Icon(Icons.badge_outlined, color: PriVaultColors.textHint),
              ),
              const SizedBox(height: 16),
              PriVaultTextField(
                controller: _usernameController,
                label: 'Username',
                hintText: 'Unique username',
                prefixIcon: const Icon(Icons.alternate_email_rounded, color: PriVaultColors.textHint),
              ),
              const SizedBox(height: 16),

              // ── Email ────────────────────────────────────────
              PriVaultTextField(
                controller: _emailController,
                label: 'Email',
                hintText: 'Email address',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined,
                    color: PriVaultColors.textHint,),
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 16),

              // ── Phone (auto-detected country) ────────────────
              const Text(
                'Phone Number',
                style: TextStyle(
                  color: PriVaultColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              IntlPhoneField(
                decoration: InputDecoration(
                  hintText: 'Phone number',
                  hintStyle: const TextStyle(
                      color: PriVaultColors.textHint, fontSize: 14,),
                  filled: true,
                  fillColor: PriVaultColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: PriVaultColors.primary, width: 1.5,),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16,),
                ),
                dropdownTextStyle:
                    const TextStyle(color: Colors.white, fontSize: 15),
                style:
                    const TextStyle(color: Colors.white, fontSize: 15),
                // Auto-detected from device locale
                initialCountryCode: _detectedCountryCode,
                onChanged: (phone) {
                  _phoneNumber = phone.completeNumber;
                },
                // Show flag + dial code in dropdown
                showDropdownIcon: true,
                dropdownIconPosition: IconPosition.trailing,
                flagsButtonPadding:
                    const EdgeInsets.symmetric(horizontal: 12),
              ),
              const SizedBox(height: 16),

              // ── Password ─────────────────────────────────────
              PriVaultTextField(
                controller: _passwordController,
                label: 'Password',
                hintText: 'Password (min. 10 characters)',
                obscureText: _obscurePassword,
                prefixIcon: const Icon(Icons.lock_outline,
                    color: PriVaultColors.textHint,),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: PriVaultColors.textHint,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 10),

              // ── Password Strength Bar ─────────────────────────
              _PasswordStrengthBar(strength: _pwStrength),
              const SizedBox(height: 10),

              // ── Password Criteria Checklist ───────────────────
              _PasswordCriteria(
                has8Chars: _has8Chars,
                hasUpper: _hasUpper,
                hasLower: _hasLower,
                hasNumber: _hasNumber,
                hasSymbol: _hasSymbol,
                // Only show when user has started typing
                visible: _passwordController.text.isNotEmpty,
              ),
              const SizedBox(height: 16),

              // ── Confirm Password ──────────────────────────────
              PriVaultTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hintText: 'Confirm password',
                obscureText: _obscureConfirmPassword,
                prefixIcon: const Icon(Icons.lock_outline,
                    color: PriVaultColors.textHint,),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: PriVaultColors.textHint,
                  ),
                  onPressed: () => setState(() =>
                      _obscureConfirmPassword = !_obscureConfirmPassword,),
                ),
                onSubmitted: (_) => _handleSignup(),
              ),
              const SizedBox(height: 32),

              // ── Sign Up Button ────────────────────────────────
              PriVaultButton(
                onPressed: isLoading ? null : _handleSignup,
                text: 'Create Account',
                isLoading: isLoading,
              ),
              const SizedBox(height: 32),

              // ── Login Link ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                        color: PriVaultColors.textSecondary,
                        fontSize: 14,),
                  ),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.login),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: PriVaultColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Password Strength Bar
// ─────────────────────────────────────────────────────────────
class _PasswordStrengthBar extends StatelessWidget {
  final double strength;
  const _PasswordStrengthBar({required this.strength});

  String get _label {
    if (strength == 0) return '';
    if (strength < 0.4) return 'Weak';
    if (strength < 0.7) return 'Fair';
    if (strength < 1.0) return 'Strong';
    return 'Very Strong';
  }

  Color get _color {
    if (strength < 0.4) return PriVaultColors.error;
    if (strength < 0.7) return PriVaultColors.warning;
    if (strength < 1.0) return const Color(0xFF22C55E);
    return PriVaultColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength,
              minHeight: 5,
              backgroundColor: PriVaultColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(_color),
            ),
          ),
        ),
        if (strength > 0) ...[
          const SizedBox(width: 10),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Password Criteria Checklist
// ─────────────────────────────────────────────────────────────
class _PasswordCriteria extends StatelessWidget {
  final bool has8Chars;
  final bool hasUpper;
  final bool hasLower;
  final bool hasNumber;
  final bool hasSymbol;
  final bool visible;

  const _PasswordCriteria({
    required this.has8Chars,
    required this.hasUpper,
    required this.hasLower,
    required this.hasNumber,
    required this.hasSymbol,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PriVaultColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PriVaultColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CriteriaRow(met: has8Chars, label: 'At least 10 characters'),
          const SizedBox(height: 6),
          _CriteriaRow(met: hasUpper, label: 'One uppercase letter (A-Z)'),
          const SizedBox(height: 6),
          _CriteriaRow(met: hasLower, label: 'One lowercase letter (a-z)'),
          const SizedBox(height: 6),
          _CriteriaRow(met: hasNumber, label: 'One number (0-9)'),
          const SizedBox(height: 6),
          _CriteriaRow(met: hasSymbol, label: 'One symbol (!@#\$%...)'),
        ],
      ),
    );
  }
}

class _CriteriaRow extends StatelessWidget {
  final bool met;
  final String label;
  const _CriteriaRow({required this.met, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: met
                ? PriVaultColors.success.withValues(alpha: 0.15)
                : Colors.transparent,
            border: Border.all(
              color: met ? PriVaultColors.success : PriVaultColors.textHint,
              width: 1.5,
            ),
          ),
          child: met
              ? const Icon(Icons.check, size: 10, color: PriVaultColors.success)
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: met ? PriVaultColors.success : PriVaultColors.textHint,
            fontWeight: met ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Google Sign-In Button (real Google G logo)
// ─────────────────────────────────────────────────────────────
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  const _GoogleSignInButton({this.onPressed, this.label = 'Continue with Google'});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    // White background circle
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r, paint);

    const cBlue = Color(0xFF4285F4);
    const cRed = Color(0xFFEA4335);
    const cYellow = Color(0xFFFBBC05);
    const cGreen = Color(0xFF34A853);

    // Red segment
    paint.color = cRed;
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy)
        ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r),
            _rad(-10), _rad(130), false,)
        ..close(),
      paint,
    );
    // Yellow segment
    paint.color = cYellow;
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy)
        ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r),
            _rad(120), _rad(70), false,)
        ..close(),
      paint,
    );
    // Green segment
    paint.color = cGreen;
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy)
        ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r),
            _rad(190), _rad(80), false,)
        ..close(),
      paint,
    );
    // Blue segment
    paint.color = cBlue;
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy)
        ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r),
            _rad(270), _rad(160), false,)
        ..close(),
      paint,
    );

    // White inner circle
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.58, paint);

    // Blue horizontal bar for the "G" crossbar
    paint.color = cBlue;
    canvas.drawRect(
      Rect.fromLTRB(cx, cy - r * 0.22, cx + r * 0.99, cy + r * 0.22),
      paint,
    );

    // White center circle to clean up
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.58, paint);
  }

  double _rad(double deg) => deg * 3.14159265 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// OR Divider
// ─────────────────────────────────────────────────────────────
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: PriVaultColors.divider)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: PriVaultColors.textHint,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: PriVaultColors.divider)),
      ],
    );
  }
}