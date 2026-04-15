// ============================================================
// PriVault – Secure Vault (device authentication)
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/ui/widgets/privault_button.dart';

import 'package:pri_vault/features/files/providers/files_provider.dart';
import 'package:pri_vault/models/file_metadata.dart';

final vaultFilesProvider = FutureProvider<List<FileMetadata>>((ref) async {
  final repo = ref.read(storageRepositoryProvider);
  return repo.getFiles(isVault: true);
});

class SecureVaultScreen extends ConsumerStatefulWidget {
  const SecureVaultScreen({super.key});

  @override
  ConsumerState<SecureVaultScreen> createState() => _SecureVaultScreenState();
}

class _SecureVaultScreenState extends ConsumerState<SecureVaultScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _unlocked = false;
  bool _busy = false;
  String? _error;
  Timer? _lockTimer;

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoLock() {
    _lockTimer?.cancel();
    _lockTimer = Timer(const Duration(minutes: 3), () {
      if (mounted) setState(() => _unlocked = false);
    });
  }

  Future<bool> _authenticateWithDevice() async {
    try {
      final bool canAuthenticate =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        return true;
      }

      return _localAuth.authenticate(
        localizedReason: 'Authenticate to access your Secure Vault',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleUnlock() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await _authenticateWithDevice();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _unlocked = ok;
      _error = ok ? null : 'Authentication failed. Try again.';
    });
    if (ok) _scheduleAutoLock();
  }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      return Scaffold(
        backgroundColor: PriVaultColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: PriVaultColors.surface2,
                    shape: BoxShape.circle,
                    border: Border.all(color: PriVaultColors.cardBorder),
                  ),
                  child: const Icon(Icons.shield_rounded, size: 44, color: PriVaultColors.primary),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your Vault',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: PriVaultColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap to authenticate with your device security',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: PriVaultColors.textSecondary, fontSize: 14),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: PriVaultColors.error)),
                ],
                const SizedBox(height: 32),
                PriVaultButton(
                  text: _busy ? 'Please wait…' : 'Tap to authenticate',
                  onPressed: _busy ? null : _handleUnlock,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filesAsync = ref.watch(vaultFilesProvider);

    return Scaffold(
      backgroundColor: PriVaultColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Vault',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your most sensitive files',
                        style: TextStyle(color: PriVaultColors.textHint, fontSize: 14),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => setState(() => _unlocked = false),
                    child: const Text('Lock', style: TextStyle(color: PriVaultColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: filesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
                  data: (files) {
                    if (files.isEmpty) return _buildEmptyState(context);
                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: files.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final file = files[i];
                        return InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: PriVaultColors.surface2,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: PriVaultColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: PriVaultColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.description_rounded, color: PriVaultColors.primary, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatBytes(file.sizeBytes),
                                        style: const TextStyle(color: PriVaultColors.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.shield_rounded, color: PriVaultColors.primary, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, size: 32, color: PriVaultColors.textHint),
          ),
          const SizedBox(height: 16),
          Text(
            'Your vault is empty',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add sensitive files to keep them secure',
            style: TextStyle(color: PriVaultColors.textHint, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
}
