// ============================================================
// PriVault – Secure Vault Screen (BR-11, BR-COMP-15)
// ============================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';
import 'package:pri_vault/features/files/providers/files_provider.dart';
import 'package:pri_vault/features/sharing/providers/sharing_provider.dart';
import 'package:pri_vault/models/file_metadata.dart';

// --- Providers ---

final vaultFilesProvider = FutureProvider<List<FileMetadata>>((ref) async {
  final repo = ref.read(storageRepositoryProvider);
  return repo.getFiles(isVault: true);
});

// --- State ---

enum VaultAccessState { locked, verifying, unlocked }

class SecureVaultScreen extends ConsumerStatefulWidget {
  const SecureVaultScreen({super.key});

  @override
  ConsumerState<SecureVaultScreen> createState() => _SecureVaultScreenState();
}

class _SecureVaultScreenState extends ConsumerState<SecureVaultScreen> {
  VaultAccessState _accessState = VaultAccessState.locked;
  final _codeController = TextEditingController();
  String? _error;
  String? _vaultToken;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    setState(() { _accessState = VaultAccessState.verifying; _error = null; });
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/secure-vault/verify-2fa');
    } catch (e) {
      setState(() { _error = e.toString(); });
    }
  }

  Future<void> _verifyOtp() async {
    try {
      final api = ref.read(apiClientProvider);
      final result = await api.post('/secure-vault/verify-2fa', body: {
        'code': _codeController.text.trim(),
      });
      if (result['vault_token'] != null) {
        setState(() {
          _vaultToken = result['vault_token'] as String;
          _accessState = VaultAccessState.unlocked;
        });
        ref.invalidate(vaultFilesProvider);
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Vault'),
        actions: [
          if (_accessState == VaultAccessState.unlocked)
            IconButton(
              icon: const Icon(Icons.lock_rounded),
              tooltip: 'Lock Vault',
              onPressed: () => setState(() {
                _accessState = VaultAccessState.locked;
                _vaultToken = null;
                _codeController.clear();
              }),
            ),
        ],
      ),
      body: switch (_accessState) {
        VaultAccessState.locked => _LockedView(onUnlock: _requestOtp),
        VaultAccessState.verifying => _VerifyView(
          controller: _codeController,
          error: _error,
          onVerify: _verifyOtp,
          onResend: _requestOtp,
        ),
        VaultAccessState.unlocked => _UnlockedView(vaultToken: _vaultToken),
      },
    );
  }
}

class _LockedView extends StatelessWidget {
  final VoidCallback onUnlock;
  const _LockedView({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PriVaultColors.primary.withValues(alpha: 0.15),
                border: Border.all(color: PriVaultColors.primary.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.lock_rounded, size: 48, color: PriVaultColors.primary),
            ),
            const SizedBox(height: 24),
            Text('Secure Vault', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Additional 2FA verification required to access vault files.\nVault files cannot be shared externally.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: PriVaultColors.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onUnlock,
              icon: const Icon(Icons.verified_user_rounded),
              label: const Text('Verify & Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifyView extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  const _VerifyView({required this.controller, this.error, required this.onVerify, required this.onResend});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email_rounded, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            const Text('Enter the 6-digit code sent to your email', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '000000',
                counterText: '',
                errorText: error,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onVerify, child: const Text('Unlock Vault')),
            const SizedBox(height: 8),
            TextButton(onPressed: onResend, child: const Text('Resend Code')),
          ],
        ),
      ),
    );
  }
}

class _UnlockedView extends ConsumerWidget {
  final String? vaultToken;
  const _UnlockedView({this.vaultToken});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(vaultFilesProvider);

    return filesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (files) {
        if (files.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.enhanced_encryption_rounded, size: 64, color: PriVaultColors.primary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text('No vault files yet', style: TextStyle(color: PriVaultColors.textSecondary)),
                const SizedBox(height: 8),
                const Text('Upload files with "Vault" enabled to add them here', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: files.length,
          itemBuilder: (context, i) {
            final file = files[i];
            return Card(
              color: PriVaultColors.surfaceLight,
              child: ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: PriVaultColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_rounded, color: PriVaultColors.primary, size: 20),
                ),
                title: Text(file.encryptedName.isNotEmpty ? 'Encrypted File' : 'Vault File',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(_formatBytes(file.sizeBytes),
                    style: const TextStyle(color: PriVaultColors.textSecondary, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: PriVaultColors.textSecondary),
              ),
            );
          },
        );
      },
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
}
