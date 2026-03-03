// ============================================================
// PriVault – Files Screen
// ============================================================
// Zero-knowledge file explorer.
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';
import 'package:pri_vault/features/auth/providers/auth_provider.dart';
import 'package:pri_vault/features/files/providers/files_provider.dart';
import 'package:pri_vault/features/sharing/providers/sharing_provider.dart';
import 'package:pri_vault/features/files/screens/file_detail_screen.dart';
import 'package:pri_vault/features/files/screens/search_screen.dart';
import 'package:pri_vault/features/trash/screens/trash_screen.dart';
import 'package:pri_vault/features/sharing/screens/share_dialog.dart';
import 'package:pri_vault/models/folder.dart';
import 'package:pri_vault/models/file_metadata.dart';

class FilesScreen extends ConsumerStatefulWidget {
  final String? folderId;
  final String? folderName;

  const FilesScreen({super.key, this.folderId, this.folderName});

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen> {
  final ValueNotifier<double> _uploadProgress = ValueNotifier(0.0);
  bool _isUploading = false;

  Future<void> _handleCreateFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      try {
        await ref.read(storageRepositoryProvider).createFolder(
              name: name.trim(),
              parentId: widget.folderId,
            );
        ref.invalidate(currentFoldersProvider(widget.folderId));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create folder: $e')),
        );
      }
    }
  }

  Future<void> _handleFileUpload() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;

    setState(() => _isUploading = true);
    _uploadProgress.value = 0.0;

    try {
      final file = File(result.files.single.path!);
      final vault = ref.read(vaultServiceProvider);

      final seedBase64 = await vault.getMasterKeySeed();
      if (seedBase64 == null) {
        throw Exception('Master key not found in vault. Please re-login.');
      }
      final masterKey = CryptoUtils.fromBase64(seedBase64);

      await ref.read(storageRepositoryProvider).uploadFileWithProgress(
            file: file,
            masterKey: masterKey,
            folderId: widget.folderId,
            progress: _uploadProgress,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File uploaded securely!')),
      );
      ref.invalidate(currentFilesProvider(widget.folderId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
        _uploadProgress.value = 0.0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(currentFoldersProvider(widget.folderId));
    final filesAsync = ref.watch(currentFilesProvider(widget.folderId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName ?? 'My Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'trash') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TrashScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'trash',
                child: ListTile(
                  leading: Icon(Icons.delete_outline_rounded),
                  title: Text('Trash'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: _isUploading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: ValueListenableBuilder<double>(
                  valueListenable: _uploadProgress,
                  builder: (_, value, __) => LinearProgressIndicator(
                    value: value > 0 ? value : null,
                  ),
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentFoldersProvider(widget.folderId));
          ref.invalidate(currentFilesProvider(widget.folderId));
        },
        child: CustomScrollView(
          slivers: [
            // Folders Section
            foldersAsync.when(
              data: (folders) => folders.isEmpty
                  ? const SliverToBoxAdapter(child: SizedBox.shrink())
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _FolderCard(folder: folders[index]),
                          childCount: folders.length,
                        ),
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Center(
                  child: Text('Error: $err'),
                ),
              ),
            ),

            // Files Section
            filesAsync.when(
              data: (files) => files.isEmpty && !foldersAsync.hasValue
                  ? _buildEmptyState()
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _FileTile(file: files[index]),
                          childCount: files.length,
                        ),
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(
                child: SizedBox.shrink(),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Center(
                  child: Text('Error: $err'),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showUploadOptions(context);
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_rounded,
              size: 80,
              color: PriVaultColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Your vault is empty',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload files to see them here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PriVaultColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder_rounded),
              title: const Text('New Folder'),
              onTap: () {
                Navigator.pop(context);
                _handleCreateFolder();
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_rounded),
              title: const Text('Upload File'),
              onTap: () {
                Navigator.pop(context);
                _handleFileUpload();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderCard extends ConsumerWidget {
  final Folder folder;
  const _FolderCard({required this.folder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                FilesScreen(folderId: folder.id, folderName: folder.name),
          ),
        );
      },
      onLongPress: () => _showFolderActions(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: PriVaultColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PriVaultColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.folder_rounded, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                folder.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.more_vert_rounded,
              size: 18,
              color: PriVaultColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                _handleRename(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _handleDelete(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRename(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: folder.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newName != null && newName.trim().isNotEmpty) {
      try {
        await ref.read(storageRepositoryProvider).renameFolder(
              folderId: folder.id,
              newName: newName.trim(),
            );
        ref.invalidate(currentFoldersProvider(folder.parentId));
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rename failed: $e')),
        );
      }
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: Text(
          'Delete "${folder.name}" and all its contents? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(storageRepositoryProvider).deleteFolder(folder.id);
        ref.invalidate(currentFoldersProvider(folder.parentId));
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }
}

class _FileTile extends ConsumerWidget {
  final FileMetadata file;
  const _FileTile({required this.file});

  Future<String> _getDecryptedName(WidgetRef ref) async {
    if (file.encryptedName.isEmpty) return 'Untitled File';

    try {
      final vault = ref.read(vaultServiceProvider);
      final encryption = ref.read(encryptionServiceProvider);

      final seedBase64 = await vault.getMasterKeySeed();
      if (seedBase64 == null) return 'Encrypted File';
      final masterKey = CryptoUtils.fromBase64(seedBase64);

      final decryptedBytes = await encryption.decrypt(
        ciphertext: CryptoUtils.fromBase64(file.encryptedName),
        key: masterKey,
      );

      return String.fromCharCodes(decryptedBytes);
    } catch (e) {
      return 'Encrypted File';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: _getDecryptedName(ref),
      builder: (context, snapshot) {
        final name = snapshot.data ?? 'Decrypting...';

        return ListTile(
          leading: Icon(
            _getFileIcon(name),
            color: PriVaultColors.primary,
          ),
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(
            children: [
              Text('${(file.sizeBytes / 1024).toStringAsFixed(1)} KB'),
              if (file.isFavorite) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: Colors.amber,
                ),
              ],
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showFileActions(context, ref, name),
          ),
          onTap: snapshot.hasData
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FileViewerScreen(
                        file: file,
                        displayName: name,
                      ),
                    ),
                  )
              : null,
        );
      },
    );
  }

  IconData _getFileIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp')) {
      return Icons.image_rounded;
    }
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (lower.endsWith('.txt') ||
        lower.endsWith('.md') ||
        lower.endsWith('.json')) {
      return Icons.description_rounded;
    }
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi')) {
      return Icons.videocam_rounded;
    }
    if (lower.endsWith('.mp3') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.aac')) {
      return Icons.audiotrack_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  void _showFileActions(
    BuildContext context,
    WidgetRef ref,
    String displayName,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.share_rounded,
                color: PriVaultColors.primary,
              ),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ShareDialog(
                    file: file,
                    decryptedName: displayName,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_rounded),
              title: const Text('View / Open'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FileViewerScreen(
                      file: file,
                      displayName: displayName,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                file.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: file.isFavorite ? Colors.amber : null,
              ),
              title: Text(
                file.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              ),
              onTap: () {
                Navigator.pop(ctx);
                _handleToggleFavorite(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _handleDelete(context, ref, displayName);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleToggleFavorite(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      await ref.read(storageRepositoryProvider).toggleFavorite(file);
      ref.invalidate(currentFilesProvider(file.folderId));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    String displayName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File?'),
        content: Text(
          'Delete "$displayName"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(storageRepositoryProvider).deleteFile(file);
        ref.invalidate(currentFilesProvider(file.folderId));
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }
}
