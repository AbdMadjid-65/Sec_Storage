// ============================================================
// PriVault – CamScanner Screen (BR-21)
// ============================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/features/files/providers/files_provider.dart';
import 'package:pri_vault/features/sharing/providers/sharing_provider.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';

class CamScannerScreen extends ConsumerStatefulWidget {
  const CamScannerScreen({super.key});

  @override
  ConsumerState<CamScannerScreen> createState() => _CamScannerScreenState();
}

class _CamScannerScreenState extends ConsumerState<CamScannerScreen> {
  File? _imageFile;
  String _extractedText = '';
  bool _isProcessing = false;
  bool _isSaving = false;

  Future<void> _captureImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
      _extractedText = '';
      _isProcessing = true;
    });

    // OCR
    try {
      final inputImage = InputImage.fromFilePath(picked.path);
      final textRecognizer = TextRecognizer();
      final result = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      setState(() {
        _extractedText = result.text;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _extractedText = 'OCR failed: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _saveToVault() async {
    if (_imageFile == null) return;
    setState(() => _isSaving = true);

    try {
      final vault = ref.read(vaultServiceProvider);
      final repo = ref.read(storageRepositoryProvider);

      final seedBase64 = await vault.getMasterKeySeed();
      if (seedBase64 == null) throw Exception('Master key not found');
      final masterKey = CryptoUtils.fromBase64(seedBase64);

      await repo.uploadFile(
        file: _imageFile!,
        masterKey: masterKey,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan saved to Files'), backgroundColor: PriVaultColors.success),
        );
        setState(() {
          _imageFile = null;
          _extractedText = '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Document Scanner',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Capture buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _captureImage(ImageSource.camera),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: PriVaultColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: PriVaultColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: PriVaultColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(height: 12),
                          Text('Camera', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _captureImage(ImageSource.gallery),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: PriVaultColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: PriVaultColors.textHint.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(height: 12),
                          Text('Gallery', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Image preview
            if (_imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(_imageFile!, height: 350, fit: BoxFit.cover),
              ),
              const SizedBox(height: 24),

              // Processing
              if (_isProcessing)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: PriVaultColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    children: [
                      CircularProgressIndicator(color: PriVaultColors.primary),
                      SizedBox(height: 16),
                      Text('Recognizing text...', style: TextStyle(color: PriVaultColors.textSecondary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),

              // Extracted text
              if (_extractedText.isNotEmpty && !_isProcessing) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: PriVaultColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: PriVaultColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.document_scanner_rounded, size: 20, color: PriVaultColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Text('Extracted Text', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SelectableText(
                        _extractedText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                              height: 1.5,
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Save button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isSaving ? null : _saveToVault,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(_isSaving ? 'Encrypting...' : 'Save to Vault', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 40),
            ] else ...[
              // Empty state
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: PriVaultColors.surfaceLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: PriVaultColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.document_scanner_rounded, size: 64, color: PriVaultColors.primary.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 20),
                    Text('Ready to Scan', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('Select an option above to begin', style: TextStyle(color: PriVaultColors.textHint)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
