import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import 'package:pri_vault/services/cloudinary_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/features/auth/providers/profile_provider.dart';

import 'package:pri_vault/core/router/app_router.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/ui/widgets/privault_button.dart';
import 'package:pri_vault/ui/widgets/privault_textfield.dart';

class UsernameSetupScreen extends ConsumerStatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  ConsumerState<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends ConsumerState<UsernameSetupScreen> {
  final _usernameController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final dn = doc.data()?['displayName'] ?? doc.data()?['display_name'];
      if (dn != null && mounted) {
        _usernameController.text = dn.toString();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _usernameController.dispose();
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

  Future<void> _saveAndContinue() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a username'), backgroundColor: PriVaultColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      String? photoUrl;
      
      // Photo upload is optional — don't let it block username save
      if (_selectedImage != null) {
        try {
          final bytes = await _selectedImage!.readAsBytes();
          // Cloudinary now uses a unique public_id per upload, so the
          // returned URL is always different — no cache busting needed.
          photoUrl = await CloudinaryService.uploadProfilePhoto(bytes, user.uid);
        } catch (storageError) {
          // Storage upload failed (rules, quota, etc.) — continue without photo
          debugPrint('Photo upload failed: $storageError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo upload failed — saving username only.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      await user.updateDisplayName(username);
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }
      await user.reload();

      // Use set + merge to avoid "document not found" errors
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'display_name': username,
        'displayName': username,
        if (photoUrl != null) 'photoUrl': photoUrl,
      }, SetOptions(merge: true),);

      // Clear Flutter's image cache so old images aren't served from memory.
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Invalidate the profile provider so it automatically streams the new data
      ref.invalidate(userProfileProvider);

      if (!mounted) return;
      context.go(AppRoutes.plan);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: PriVaultColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PriVaultColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Almost there!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add a photo (optional) — username is pre-filled from signup',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: PriVaultColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),

              // Avatar Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: PriVaultColors.primaryGradient,
                          image: _selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _selectedImage == null
                            ? const Icon(
                                Icons.camera_alt_outlined,
                                size: 48,
                                color: Colors.white,
                              )
                            : null,
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
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: PriVaultColors.primary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Username Field
              PriVaultTextField(
                controller: _usernameController,
                label: 'Username',
                hintText: 'Username',
                prefixIcon: const Icon(Icons.alternate_email_rounded, color: PriVaultColors.textHint),
              ),
              const SizedBox(height: 32),

              // Continue Button
              PriVaultButton(
                onPressed: _isLoading ? null : _saveAndContinue,
                text: 'Continue',
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
