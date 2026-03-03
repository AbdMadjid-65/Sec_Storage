import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';
import 'package:pri_vault/features/auth/providers/auth_provider.dart';
import 'package:pri_vault/features/sharing/providers/sharing_provider.dart';
import 'package:pri_vault/models/file_metadata.dart';
import 'package:pri_vault/models/share_models.dart';

class ShareDialog extends ConsumerStatefulWidget {
  final FileMetadata file;
  final String decryptedName;

  const ShareDialog({
    super.key,
    required this.file,
    required this.decryptedName,
  });

  @override
  ConsumerState<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends ConsumerState<ShareDialog> {
  String? _generatedLink;

  final _emailController = TextEditingController();

  Future<void> _createPublicLink() async {
    try {
      final url = await ref
          .read(sharingProvider.notifier)
          .createPublicLink(widget.file);
      if (url != null) {
        setState(() => _generatedLink = url);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create link: $e')),
      );
    }
  }

  Future<void> _shareWithUser() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    try {
      await ref.read(sharingProvider.notifier).shareWithUser(
            file: widget.file,
            email: email,
          );

      _emailController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shared securely with $email')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share: $e')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: PriVaultColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.share_rounded,
                    color: PriVaultColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Share "${widget.decryptedName}"',
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Public Link'),
                Tab(text: 'Add User'),
              ],
            ),
            SizedBox(
              height: 300,
              child: TabBarView(
                children: [
                  _buildPublicLinkTab(),
                  _buildAddUserTab(),
                ],
              ),
            ),
            _buildActiveSharesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicLinkTab() {
    final sharingState = ref.watch(sharingProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create a zero-knowledge link. The decryption key is embedded in the URL and never sent to our servers.',
            style: TextStyle(color: PriVaultColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (sharingState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_generatedLink != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PriVaultColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: PriVaultColors.primary.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  SelectableText(
                    _generatedLink!,
                    style: const TextStyle(
                      color: PriVaultColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generatedLink!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy Link'),
                  ),
                ],
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _createPublicLink,
              icon: const Icon(Icons.link_rounded),
              label: const Text('Generate Secure Link'),
            ),
        ],
      ),
    );
  }

  Widget _buildAddUserTab() {
    final sharingState = ref.watch(sharingProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Share directly with another PriVault user. The file key is encrypted with their public key.',
            style: TextStyle(color: PriVaultColors.textSecondary),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'User Email',
              prefixIcon: Icon(Icons.email_rounded),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          if (sharingState.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton.icon(
              onPressed: _shareWithUser,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Share Internally'),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveSharesList() {
    final sharesAsync = ref.watch(fileSharesProvider(widget.file.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            'Active Shares',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          height: 120,
          child: sharesAsync.when(
            data: (shares) {
              if (shares.isEmpty) {
                return const Center(
                  child: Text(
                    'No active shares',
                    style: TextStyle(color: PriVaultColors.textSecondary),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: shares.length,
                itemBuilder: (context, index) {
                  final share = shares[index];
                  return ListTile(
                    leading: Icon(
                      share.type == 'link'
                          ? Icons.link_rounded
                          : Icons.person_rounded,
                      color: PriVaultColors.textSecondary,
                    ),
                    title: Text(
                      share.type == 'link' ? 'Public Link' : 'Shared with User',
                    ),
                    subtitle: Text(
                      'Created: ${share.createdAt?.toIso8601String().split('T').first ?? "Unknown"}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.cancel_rounded,
                        color: Colors.redAccent,
                      ),
                      onPressed: () async {
                        await ref
                            .read(shareRepositoryProvider)
                            .revokeShare(share.id);
                        ref.invalidate(fileSharesProvider(widget.file.id));
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }
}
