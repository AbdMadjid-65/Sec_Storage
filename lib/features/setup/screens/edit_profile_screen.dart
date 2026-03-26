import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'package:pri_vault/services/cloudinary_service.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/core/router/app_router.dart';
import 'package:pri_vault/features/auth/providers/auth_provider.dart';
import 'package:pri_vault/features/auth/providers/profile_provider.dart';
import 'package:pri_vault/ui/widgets/privault_button.dart';
import 'package:pri_vault/ui/widgets/privault_textfield.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  File? _selectedImage;
  String? _existingPhotoUrl;
  bool _isLoading = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  void _loadCurrentProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _usernameController.text = user.displayName ?? '';
    _emailController.text = user.email ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profile = ref.read(userProfileProvider).valueOrNull;
      setState(() {
        _existingPhotoUrl = profile?['photoUrl'] as String? ?? user.photoURL;
      });
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validation
    if (currentPassword.isEmpty) {
      _showError('Please enter your current password');
      return;
    }
    if (newPassword.isEmpty) {
      _showError('Please enter a new password');
      return;
    }
    if (newPassword.length < 8) {
      _showError('New password must be at least 8 characters');
      return;
    }
    if (newPassword != confirmPassword) {
      _showError('New passwords do not match');
      return;
    }
    if (currentPassword == newPassword) {
      _showError('New password must be different from current password');
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        _showError('User not found. Please log in again.');
        return;
      }

      final email = user.email!;

      // Step 1: Re-authenticate with current password
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Step 2: Update password in Firebase Auth
      await user.updatePassword(newPassword);

      // Step 3: Sign out
      await ref.read(authStateProvider.notifier).signOut();

      // Step 4: Show success and navigate to login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully! Please log in again.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go(AppRoutes.login);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _showError('Current password is incorrect');
      } else if (e.code == 'weak-password') {
        _showError('New password is too weak');
      } else if (e.code == 'requires-recent-login') {
        _showError('Please log out and log in again before changing password');
      } else {
        _showError('Failed to change password: ${e.message}');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      String? newPhotoUrl = _existingPhotoUrl;
      bool didUploadNewPhoto = false;

      // 1. Upload new photo if selected.
      if (_selectedImage != null) {
        try {
          final bytes = await _selectedImage!.readAsBytes();
          newPhotoUrl = await CloudinaryService.uploadProfilePhoto(bytes, user.uid);
          didUploadNewPhoto = true;
        } catch (storageError) {
          debugPrint('Photo upload failed: $storageError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo upload failed — saving other changes only.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      // 2. Update Firestore
      final firestoreUpdates = <String, dynamic>{};
      if (_usernameController.text.trim().isNotEmpty) firestoreUpdates['display_name'] = _usernameController.text.trim();
      if (newPhotoUrl != null) firestoreUpdates['photoUrl'] = newPhotoUrl;
      if (firestoreUpdates.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(firestoreUpdates, SetOptions(merge: true));
      }

      // 3. Update Firebase Auth profile
      if (_usernameController.text.trim().isNotEmpty) {
        await user.updateDisplayName(_usernameController.text.trim());
      }
      if (didUploadNewPhoto) {
        await user.updatePhotoURL(newPhotoUrl);
      }

      // 4. Update Email (requires recent login)
      final newEmail = _emailController.text.trim();
      if (newEmail.isNotEmpty && newEmail != user.email) {
        await user.verifyBeforeUpdateEmail(newEmail);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification email sent to new address.'), backgroundColor: PriVaultColors.info),
          );
        }
      }

      // 5. Clear image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // 6. Update local state
      if (didUploadNewPhoto) {
        setState(() => _existingPhotoUrl = newPhotoUrl);
      }

      // 7. Invalidate profile provider
      ref.invalidate(userProfileProvider);

      if (!mounted) return;
      _showSuccess('Profile updated successfully!');
      context.pop();
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: PriVaultColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PriVaultColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                   GestureDetector(
                     onTap: () => context.pop(),
                     child: Container(
                       width: 40,
                       height: 40,
                       decoration: BoxDecoration(
                         color: PriVaultColors.surfaceLight,
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: PriVaultColors.cardBorder),
                       ),
                       child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Text(
                       'Edit Profile',
                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
                             fontWeight: FontWeight.w700,
                             color: Colors.white,
                           ),
                     ),
                   ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar Picker
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              key: ValueKey(_existingPhotoUrl ?? FirebaseAuth.instance.currentUser?.uid),
                              width: 128,
                              height: 128,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: PriVaultColors.primaryGradient,
                              ),
                              child: ClipOval(
                                child: _selectedImage != null
                                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                    : (_existingPhotoUrl != null
                                        ? Image.network(_existingPhotoUrl!, fit: BoxFit.cover)
                                        : const Icon(Icons.person_rounded, size: 64, color: Colors.white)),
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: PriVaultColors.background, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.indigoAccent, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Username
                    PriVaultTextField(
                      controller: _usernameController,
                      label: 'Username',
                      hintText: 'Enter username',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: PriVaultColors.textHint),
                    ),
                    const SizedBox(height: 24),

                    // Email
                    PriVaultTextField(
                      controller: _emailController,
                      label: 'Email',
                      hintText: 'Enter new email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.mail_outline_rounded, color: PriVaultColors.textHint),
                    ),
                    const SizedBox(height: 24),

                    // Save Profile Button
                    PriVaultButton(
                      text: 'Save Profile',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _saveProfile,
                    ),
                    const SizedBox(height: 32),

                    // ─── Change Password Section ───
                    Row(
                      children: [
                         Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1))),
                         const Padding(
                           padding: EdgeInsets.symmetric(horizontal: 16),
                           child: Text('Change Password', style: TextStyle(color: PriVaultColors.textHint, fontSize: 12)),
                         ),
                         Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1))),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Current Password
                    PriVaultTextField(
                      controller: _currentPasswordController,
                      label: 'Current Password',
                      hintText: 'Enter current password',
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: PriVaultColors.textHint),
                    ),
                    const SizedBox(height: 24),

                    // New Password
                    PriVaultTextField(
                      controller: _newPasswordController,
                      label: 'New Password',
                      hintText: 'Enter new password',
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: PriVaultColors.textHint),
                    ),
                    const SizedBox(height: 8),

                    // Password Strength Indicator
                    _PasswordStrengthIndicator(controller: _newPasswordController),
                    const SizedBox(height: 24),

                    // Confirm New Password
                    PriVaultTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm New Password',
                      hintText: 'Re-enter new password',
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: PriVaultColors.textHint),
                    ),
                    const SizedBox(height: 32),

                    // Change Password Button
                    PriVaultButton(
                      text: 'Change Password',
                      isLoading: _isChangingPassword,
                      onPressed: _isChangingPassword ? null : _changePassword,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Password Strength Indicator Widget ─────────────────────────

class _PasswordStrengthIndicator extends StatefulWidget {
  final TextEditingController controller;
  const _PasswordStrengthIndicator({required this.controller});

  @override
  State<_PasswordStrengthIndicator> createState() => _PasswordStrengthIndicatorState();
}

class _PasswordStrengthIndicatorState extends State<_PasswordStrengthIndicator> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  ({int score, String label, Color color, List<_StrengthCheck> checks}) _evaluate(String password) {
    final checks = [
      _StrengthCheck('At least 8 characters', password.length >= 8),
      _StrengthCheck('Contains uppercase', password.contains(RegExp(r'[A-Z]'))),
      _StrengthCheck('Contains lowercase', password.contains(RegExp(r'[a-z]'))),
      _StrengthCheck('Contains number', password.contains(RegExp(r'[0-9]'))),
      _StrengthCheck('Contains special character', password.contains(RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]{};:,.<>?/\\|`~]'))),
    ];

    final score = checks.where((c) => c.passed).length;

    String label;
    Color color;
    if (password.isEmpty) {
      label = '';
      color = Colors.transparent;
    } else if (score <= 2) {
      label = 'Weak';
      color = Colors.redAccent;
    } else if (score <= 3) {
      label = 'Fair';
      color = Colors.orangeAccent;
    } else if (score <= 4) {
      label = 'Good';
      color = Colors.amber;
    } else {
      label = 'Strong';
      color = Colors.greenAccent.shade400;
    }

    return (score: score, label: label, color: color, checks: checks);
  }

  @override
  Widget build(BuildContext context) {
    final password = widget.controller.text;
    if (password.isEmpty) return const SizedBox.shrink();

    final result = _evaluate(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: result.score / 5,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(result.color),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              result.label,
              style: TextStyle(
                color: result.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Checks list
        for (final check in result.checks)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  check.passed ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 14,
                  color: check.passed ? Colors.greenAccent.shade400 : PriVaultColors.textHint,
                ),
                const SizedBox(width: 8),
                Text(
                  check.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: check.passed ? Colors.greenAccent.shade400 : PriVaultColors.textHint,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StrengthCheck {
  final String label;
  final bool passed;
  const _StrengthCheck(this.label, this.passed);
}
