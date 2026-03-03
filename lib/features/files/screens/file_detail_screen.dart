// ============================================================
// PriVault – File Viewer Screen
// ============================================================
// Downloads, decrypts, and renders file content by MIME type.
// ============================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/features/files/providers/files_provider.dart';
import 'package:pri_vault/features/sharing/providers/sharing_provider.dart';
import 'package:pri_vault/models/file_metadata.dart';
import 'package:pri_vault/models/share_models.dart';

class FileViewerScreen extends ConsumerStatefulWidget {
  final FileMetadata file;
  final String displayName;
  final SharedFile? sharedFile;

  const FileViewerScreen({
    super.key,
    required this.file,
    required this.displayName,
    this.sharedFile,
  });

  @override
  ConsumerState<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends ConsumerState<FileViewerScreen> {
  Uint8List? _decryptedBytes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      final vault = ref.read(vaultServiceProvider);
      final encryptionService = ref.read(encryptionServiceProvider);
      final storageRepo = ref.read(storageRepositoryProvider);

      Uint8List fileKey;

      if (widget.sharedFile != null) {
        // Shared file flow
        final shared = widget.sharedFile!;

        // For shared files, decrypt using recipient's encrypted key
        final privKeyB64 = await vault.getSharingPrivateKey();
        if (privKeyB64 == null) throw Exception('Sharing keys not found');

        final seedBase64 = await vault.getMasterKeySeed();
        if (seedBase64 == null) throw Exception('Master key not found');
        final masterKey = CryptoUtils.fromBase64(seedBase64);

        // Decrypt file key from the recipient's encrypted key
        if (shared.recipientShare.encryptedKey == null) throw Exception('Encrypted key missing');
        final encryptedFileKey = CryptoUtils.fromBase64(shared.recipientShare.encryptedKey!);
        fileKey = await encryptionService.decrypt(
          ciphertext: encryptedFileKey,
          key: masterKey,
        );
      } else {
        // Owner flow: use master key
        final seedBase64 = await vault.getMasterKeySeed();
        if (seedBase64 == null) {
          throw Exception('Master key not found. Please re-login.');
        }
        final masterKey = CryptoUtils.fromBase64(seedBase64);

        final encryptedFileKey =
            CryptoUtils.fromBase64(widget.file.fileKeyEncrypted!);
        fileKey = await encryptionService.decrypt(
          ciphertext: encryptedFileKey,
          key: masterKey,
        );
      }

      // Download and decrypt actual file content
      final bytes = await storageRepo.downloadFile(
        widget.file,
        fileKey,
      );

      if (!mounted) return;
      setState(() {
        _decryptedBytes = bytes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _inferType() {
    final name = widget.displayName.toLowerCase();
    if (name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.gif') ||
        name.endsWith('.webp') ||
        name.endsWith('.bmp')) {
      return 'image';
    }
    if (name.endsWith('.txt') ||
        name.endsWith('.md') ||
        name.endsWith('.json') ||
        name.endsWith('.csv') ||
        name.endsWith('.log') ||
        name.endsWith('.xml') ||
        name.endsWith('.yaml') ||
        name.endsWith('.yml')) {
      return 'text';
    }
    if (name.endsWith('.pdf')) {
      return 'pdf';
    }
    return 'binary';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.displayName,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_decryptedBytes != null)
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              tooltip: 'File Info',
              onPressed: () => _showFileInfo(context),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Decrypting file...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PriVaultColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to decrypt file',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PriVaultColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadFile();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final bytes = _decryptedBytes!;
    final type = _inferType();

    switch (type) {
      case 'image':
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
            ),
          ),
        );
      case 'text':
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            String.fromCharCodes(bytes),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
          ),
        );
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insert_drive_file_rounded,
                size: 80,
                color: PriVaultColors.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                widget.displayName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${(bytes.length / 1024).toStringAsFixed(1)} KB',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PriVaultColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Preview not available for this file type.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PriVaultColors.textSecondary,
                    ),
              ),
            ],
          ),
        );
    }
  }

  void _showFileInfo(BuildContext context) {
    final bytes = _decryptedBytes;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _InfoRow(
                label: 'Name',
                value: widget.displayName,
              ),
              _InfoRow(
                label: 'Size (original)',
                value: '${((bytes?.length ?? 0) / 1024).toStringAsFixed(1)} KB',
              ),
              _InfoRow(
                label: 'Type',
                value: _inferType().toUpperCase(),
              ),
              const _InfoRow(
                label: 'Encrypted',
                value: 'Yes (XChaCha20-Poly1305)',
              ),
              if (widget.file.createdAt != null)
                _InfoRow(
                  label: 'Uploaded',
                  value: widget.file.createdAt.toString().split('.').first,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PriVaultColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
