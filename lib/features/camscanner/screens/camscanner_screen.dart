// ============================================================
// PriVault – CamScanner Screen (BR-21)
// ============================================================

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pri_vault/core/api/api_client.dart';
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
      appBar: AppBar(title: const Text('CamScanner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Capture buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _captureImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _captureImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Image preview
            if (_imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_imageFile!, height: 300, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),

              // Processing
              if (_isProcessing)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Recognizing text...', style: TextStyle(color: PriVaultColors.textSecondary)),
                    ],
                  ),
                ),

              // Extracted text
              if (_extractedText.isNotEmpty && !_isProcessing) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PriVaultColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: PriVaultColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.text_snippet_rounded, size: 18, color: PriVaultColors.primary),
                          const SizedBox(width: 8),
                          Text('Extracted Text', style: Theme.of(context).textTheme.titleSmall),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _extractedText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Save button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveToVault,
                icon: _isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_rounded),
                label: Text(_isSaving ? 'Saving...' : 'Encrypt & Save to Files'),
              ),
            ] else ...[
              // Empty state
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: PriVaultColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PriVaultColors.divider, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.document_scanner_rounded, size: 64, color: PriVaultColors.primary.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    const Text('Scan a document', style: TextStyle(color: PriVaultColors.textSecondary)),
                    const SizedBox(height: 4),
                    const Text('Capture, OCR, and encrypt-save', style: TextStyle(color: Colors.white38, fontSize: 12)),
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
