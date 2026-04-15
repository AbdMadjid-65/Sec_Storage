// ============================================================
// PriVault – Login Screen
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pri_vault/core/router/app_router.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/features/auth/providers/auth_provider.dart';
import 'package:pri_vault/ui/widgets/privault_button.dart';
import 'package:pri_vault/ui/widgets/privault_textfield.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;

    await ref
        .read(authStateProvider.notifier)
        .signIn(email: email, password: password);

    if (!mounted) return;
    final authState = ref.read(authStateProvider);

    if (authState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(authState.error!),
        backgroundColor: PriVaultColors.error,
      ),);
    } else if (authState.status == AuthStatus.authenticated) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    await ref.read(authStateProvider.notifier).signInWithGoogle();

    if (!mounted) return;
    final authState = ref.read(authStateProvider);

    if (authState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(authState.error!),
        backgroundColor: PriVaultColors.error,
      ),);
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
                'Welcome back',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to access your vault',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: PriVaultColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),

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

              // ── Password ─────────────────────────────────────
              PriVaultTextField(
                controller: _passwordController,
                label: 'Password',
                hintText: 'Password',
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
                onSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: 12),

              // ── Forgot Password ──────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: PriVaultColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Login Button ─────────────────────────────────
              PriVaultButton(
                onPressed: isLoading ? null : _handleLogin,
                text: 'Login',
                isLoading: isLoading,
              ),
              const SizedBox(height: 32),

              // ── Divider ──────────────────────────────────────
              _OrDivider(),
              const SizedBox(height: 32),

              // ── Google Button ────────────────────────────────
              _GoogleSignInButton(
                onPressed: isLoading ? null : _handleGoogleSignIn,
              ),
              const SizedBox(height: 12),

              // ── Twitter (disabled) ───────────────────────────
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.flutter_dash,
                    size: 20, color: PriVaultColors.textHint,),
                label: const Text(
                  'Twitter (Coming Soon)',
                  style: TextStyle(
                      color: PriVaultColors.textHint,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor:
                      Colors.white.withValues(alpha: 0.05),
                  side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),),
                ),
              ),
              const SizedBox(height: 48),

              // ── Sign Up Link ─────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                        color: PriVaultColors.textSecondary, fontSize: 14,),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.signup),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: PriVaultColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Reusable Google Sign-In Button with real Google logo
// ─────────────────────────────────────────────────────────────
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _GoogleSignInButton({this.onPressed});

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Real Google "G" logo drawn with CustomPainter
            SizedBox(
              width: 24,
              height: 24,
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: TextStyle(
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

// ─────────────────────────────────────────────────────────────
// Google "G" logo — drawn with CustomPainter (no SVG package needed)
// ─────────────────────────────────────────────────────────────
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    // Colors
    const cBlue = Color(0xFF4285F4);
    const cRed = Color(0xFFEA4335);
    const cYellow = Color(0xFFFBBC05);
    const cGreen = Color(0xFF34A853);

    final paint = Paint()..style = PaintingStyle.fill;

    // Draw the circle background white first
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r, paint);

    // ── Red arc (top-right to bottom) ──
    paint.color = cRed;
    final redPath = Path()
      ..moveTo(cx, cy)
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r),
          -_deg(10), _deg(130), false,)
      ..close();
    canvas.drawPath(redPath, paint);

    // ── Yellow arc (bottom-left) ──
    paint.color = cYellow;
    final yellowPath = Path()
      ..moveTo(cx, cy)
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r),
          _deg(120), _deg(70), false,)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // ── Green arc (bottom-right) ──
    paint.color = cGreen;
    final greenPath = Path()
      ..moveTo(cx, cy)
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r),
          _deg(190), _deg(80), false,)
      ..close();
    canvas.drawPath(greenPath, paint);

    // ── Blue arc (top-left + right bar) ──
    paint.color = cBlue;
    final bluePath = Path()
      ..moveTo(cx, cy)
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r),
          _deg(270), _deg(160), false,)
      ..close();
    canvas.drawPath(bluePath, paint);

    // White inner circle (donut effect)
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.58, paint);

    // Blue right bar of the "G"
    paint.color = cBlue;
    canvas.drawRect(
      Rect.fromLTRB(cx, cy - r * 0.22, cx + r, cy + r * 0.22),
      paint,
    );

    // White center circle again to clean up bar overlap
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.58, paint);

    // Redraw blue bar clipped to right half only
    paint.color = cBlue;
    canvas.drawRect(
      Rect.fromLTRB(cx, cy - r * 0.22, cx + r * 0.99, cy + r * 0.22),
      paint,
    );

    // Final white inner circle
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.58, paint);
  }

  double _deg(double degrees) => degrees * 3.14159265 / 180;

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
        Expanded(
            child: Container(height: 1, color: PriVaultColors.divider),),
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
        Expanded(
            child: Container(height: 1, color: PriVaultColors.divider),),
      ],
    );
  }
}