// ============================================================
// PriVault – Files Screen
// ============================================================
// Zero-knowledge file explorer.
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';

import 'package:pri_vault/features/files/providers/files_provider.dart';
import 'package:pri_vault/features/sharing/providers/sharing_provider.dart';
import 'package:pri_vault/features/files/screens/file_detail_screen.dart';
import 'package:pri_vault/features/files/screens/search_screen.dart';
import 'package:pri_vault/features/trash/screens/trash_screen.dart';
import 'package:pri_vault/features/sharing/screens/share_dialog.dart';
import 'package:pri_vault/models/folder.dart';
import 'package:pri_vault/models/file_metadata.dart';
import 'package:pri_vault/models/share_models.dart';

bool _mimeMatchesFilter(String mime, String tab) {
  final m = mime.toLowerCase();
  switch (tab) {
    case 'All':
      return true;
    case 'Images':
      return m.startsWith('image/');
    case 'Documents':
      return m.startsWith('application/pdf') ||
          m.contains('word') ||
          m.contains('msword') ||
          m.contains('spreadsheet') ||
          m.contains('presentation') ||
          m.startsWith('text/');
    case 'Videos':
      return m.startsWith('video/');
    case 'Music':
      return m.startsWith('audio/');
    default:
      return true;
  }
}

class FilesScreen extends ConsumerStatefulWidget {
  final String? folderId;
  final String? folderName;
  final String? initialTab;
  /// `my` | `sharedBy` | `sharedWith`
  final String? initialFilesScope;

  const FilesScreen({
    super.key,
    this.folderId,
    this.folderName,
    this.initialTab,
    this.initialFilesScope,
  });

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen> {
  final ValueNotifier<double> _uploadProgress = ValueNotifier(0.0);
  bool _isUploading = false;
  String _viewMode = 'grid';
  late String _activeTab;
  late String _filesScope;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab ?? 'All';
    _filesScope = widget.initialFilesScope ?? 'my';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    if (extra == null) return;
    final tab = extra['initialTab'] as String?;
    final scope = extra['filesScope'] as String?;
    var changed = false;
    if (tab != null && tab != _activeTab) {
      _activeTab = tab;
      changed = true;
    }
    if (scope != null && scope != _filesScope) {
      _filesScope = scope;
      changed = true;
    }
    if (changed && mounted) setState(() {});
  }

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

  Widget _scopePill(String label, String scope) {
    final sel = _filesScope == scope;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _filesScope = scope),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? PriVaultColors.primary : PriVaultColors.surface2,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: sel ? PriVaultColors.primary : PriVaultColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: sel ? Colors.white : PriVaultColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(currentFoldersProvider(widget.folderId));
    final filesAsync = ref.watch(currentFilesProvider(widget.folderId));
    final pathAsync = ref.watch(folderPathProvider(widget.folderId));
    final atRoot = widget.folderId == null;
    final showMy = !atRoot || _filesScope == 'my';

    return Scaffold(
      backgroundColor: PriVaultColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          widget.folderName ?? 'My Files',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            color: PriVaultColors.surfaceLight,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  leading: Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  title: Text('Trash', style: TextStyle(color: Colors.redAccent)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: _isUploading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: ValueListenableBuilder<double>(
                  valueListenable: _uploadProgress,
                  builder: (_, value, __) => LinearProgressIndicator(
                    value: value > 0 ? value : null,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(PriVaultColors.primary),
                  ),
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentFoldersProvider(widget.folderId));
          ref.invalidate(currentFilesProvider(widget.folderId));
          ref.invalidate(ownerSharesProvider);
          ref.invalidate(sharedWithMeLiveProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Header, Search, Tabs
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (atRoot) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _scopePill('My Files', 'my'),
                            _scopePill('Shared by me', 'sharedBy'),
                            _scopePill('Shared with me', 'sharedWith'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (showMy) ...[
                    // Search Bar
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      ),
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: PriVaultColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: PriVaultColors.cardBorder),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search_rounded, color: PriVaultColors.textHint),
                            SizedBox(width: 12),
                            Text(
                              'Search files...',
                              style: TextStyle(color: PriVaultColors.textHint, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    pathAsync.when(
                      data: (path) => path.isEmpty
                          ? const SizedBox.shrink()
                          : SizedBox(
                              height: 30,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) {
                                  final folder = path[index];
                                  final isLast = index == path.length - 1;
                                  return GestureDetector(
                                    onTap: isLast
                                        ? null
                                        : () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => FilesScreen(
                                                  folderId: folder.id,
                                                  folderName: folder.name,
                                                ),
                                              ),
                                            );
                                          },
                                    child: Text(
                                      folder.name,
                                      style: TextStyle(
                                        color: isLast
                                            ? Colors.white
                                            : PriVaultColors.textHint,
                                        fontSize: 12,
                                        fontWeight: isLast
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  );
                                },
                                separatorBuilder: (_, __) => const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    size: 14,
                                    color: PriVaultColors.textHint,
                                  ),
                                ),
                                itemCount: path.length,
                              ),
                            ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 8),

                    // Filter Tabs & View Toggle
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: ['All', 'Images', 'Documents', 'Videos', 'Music'].map((tab) {
                                final isActive = tab == _activeTab;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: InkWell(
                                    onTap: () => setState(() => _activeTab = tab),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: isActive ? PriVaultColors.primaryGradient : null,
                                        color: isActive ? null : PriVaultColors.surfaceLight,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        tab,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isActive ? Colors.white : PriVaultColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            InkWell(
                              onTap: () => setState(() => _viewMode = 'grid'),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: _viewMode == 'grid' ? PriVaultColors.primary : PriVaultColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.grid_view_rounded, size: 20, color: _viewMode == 'grid' ? Colors.white : PriVaultColors.textHint),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => setState(() => _viewMode = 'list'),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: _viewMode == 'list' ? PriVaultColors.primary : PriVaultColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.list_rounded, size: 20, color: _viewMode == 'list' ? Colors.white : PriVaultColors.textHint),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),

            // Folders Header
            if (showMy)
            foldersAsync.when(
              data: (folders) => folders.isEmpty
                  ? const SliverToBoxAdapter(child: SizedBox.shrink())
                  : const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Text(
                          'Folders',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: PriVaultColors.textHint),
                        ),
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // Folders Section
            if (showMy)
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
                          childAspectRatio: 1.1,
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

            // Files Header
            if (showMy)
            filesAsync.when(
              data: (files) => files.isEmpty
                  ? const SliverToBoxAdapter(child: SizedBox.shrink())
                  : const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Text(
                          'Files',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: PriVaultColors.textHint),
                        ),
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // Files Section
            if (showMy)
            filesAsync.when(
              data: (files) {
                final folders = foldersAsync.valueOrNull ?? [];
                final filtered = files
                    .where((f) => _mimeMatchesFilter(f.mimeType, _activeTab))
                    .toList();
                if (files.isEmpty && folders.isEmpty) {
                  return _buildEmptyState();
                }
                if (filtered.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          files.isEmpty
                              ? 'No files in this folder yet'
                              : 'No files match this filter',
                          style: const TextStyle(color: PriVaultColors.textSecondary),
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: _viewMode == 'grid'
                          ? SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _FileTile(file: filtered[index], isGrid: true),
                                childCount: filtered.length,
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _FileTile(file: filtered[index], isGrid: false),
                                ),
                                childCount: filtered.length,
                              ),
                            ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: SizedBox.shrink(),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Center(
                  child: Text('Error: $err', style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
            if (!showMy)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: _SharedFilesScopeContent(scope: _filesScope),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)), // Padding for FAB
          ],
        ),
      ),
      floatingActionButton: showMy
          ? Container(
              margin: const EdgeInsets.only(bottom: 16, right: 8),
              child: FloatingActionButton.extended(
                onPressed: () => _showUploadOptions(context),
                backgroundColor: Colors.transparent,
                elevation: 0,
                label: const SizedBox.shrink(),
                icon: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: PriVaultColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: PriVaultColors.primary.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                ),
              ),
            )
          : null,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
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

class _SharedFilesScopeContent extends ConsumerWidget {
  final String scope;

  const _SharedFilesScopeContent({required this.scope});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (scope == 'sharedBy') {
      return ref.watch(ownerSharesProvider).when(
            data: (rows) {
              if (rows.isEmpty) {
                return _emptyBox('Nothing you\'ve shared yet');
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final share = rows[i].$1;
                  final file = rows[i].$2;
                  if (file == null) {
                    return ListTile(
                      title: Text('Share ${share.id}', style: const TextStyle(color: PriVaultColors.textPrimary)),
                      subtitle: const Text('File unavailable', style: TextStyle(color: PriVaultColors.textHint)),
                    );
                  }
                  return _SharedFileRow(file: file, share: share);
                },
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            error: (e, _) => Text('Error: $e', style: const TextStyle(color: PriVaultColors.error)),
          );
    }
    return ref.watch(sharedWithMeLiveProvider).when(
          data: (items) {
            if (items.isEmpty) {
              return _emptyBox('No files shared with you yet');
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final sf = items[i];
                return _SharedFileRow(file: sf.file, share: sf.parentShare);
              },
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          error: (e, _) => Text('Error: $e', style: const TextStyle(color: PriVaultColors.error)),
        );
  }

  Widget _emptyBox(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.folder_shared_rounded, size: 48, color: PriVaultColors.textHint),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: PriVaultColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SharedFileRow extends ConsumerWidget {
  final FileMetadata file;
  final Share share;

  const _SharedFileRow({
    required this.file,
    required this.share,
  });

  Future<String> _name(WidgetRef ref) async {
    if (file.encryptedName.isEmpty) return 'File';
    try {
      final vault = ref.read(vaultServiceProvider);
      final encryption = ref.read(encryptionServiceProvider);
      final seedBase64 = await vault.getMasterKeySeed();
      if (seedBase64 == null) return 'Encrypted file';
      final masterKey = CryptoUtils.fromBase64(seedBase64);
      final decryptedBytes = await encryption.decrypt(
        ciphertext: CryptoUtils.fromBase64(file.encryptedName),
        key: masterKey,
      );
      return String.fromCharCodes(decryptedBytes);
    } catch (_) {
      return 'Encrypted file';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: _name(ref),
      builder: (context, snap) {
        final name = snap.data ?? '…';
        return Material(
          color: PriVaultColors.surface2,
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: PriVaultColors.cardBorder),
            ),
            leading: const Icon(Icons.insert_drive_file_rounded, color: PriVaultColors.primary),
            title: Text(name, style: const TextStyle(color: PriVaultColors.textPrimary)),
            subtitle: Text(
              share.type == 'link' ? 'Link share' : 'Shared',
              style: const TextStyle(color: PriVaultColors.textHint, fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.share_rounded, color: PriVaultColors.primary, size: 22),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ShareDialog(file: file, decryptedName: name),
                );
              },
            ),
            onTap: () {
              if (!snap.hasData) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FileViewerScreen(file: file, displayName: name),
                ),
              );
            },
          ),
        );
      },
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PriVaultColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PriVaultColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: PriVaultColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.folder_rounded, color: Colors.white, size: 24),
            ),
            const Spacer(),
            Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Folder',
              style: TextStyle(
                fontSize: 12,
                color: PriVaultColors.textSecondary,
              ),
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
  final bool isGrid;
  const _FileTile({required this.file, this.isGrid = false});

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

        if (isGrid) {
          return InkWell(
            onTap: snapshot.hasData
                ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FileViewerScreen(file: file, displayName: name)))
                : null,
            onLongPress: () => _showFileActions(context, ref, name),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PriVaultColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PriVaultColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [PriVaultColors.primary.withValues(alpha: 0.2), PriVaultColors.secondary.withValues(alpha: 0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(_getFileIcon(name), color: PriVaultColors.primary, size: 32),
                        ),
                      ),
                      if (!file.isVaultFile && snapshot.hasData)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.45),
                              minimumSize: const Size(32, 32),
                              padding: EdgeInsets.zero,
                            ),
                            icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => ShareDialog(file: file, decryptedName: name),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(file.sizeBytes / 1024).toStringAsFixed(1)} KB',
                        style: const TextStyle(fontSize: 10, color: PriVaultColors.textSecondary),
                      ),
                      if (file.isFavorite)
                        const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return InkWell(
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
          onLongPress: () => _showFileActions(context, ref, name),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: PriVaultColors.surfaceLight,
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
                  child: Icon(
                    _getFileIcon(name),
                    color: PriVaultColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${(file.sizeBytes / 1024).toStringAsFixed(1)} KB',
                            style: const TextStyle(
                              fontSize: 12,
                              color: PriVaultColors.textSecondary,
                            ),
                          ),
                          if (file.isFavorite) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (!file.isVaultFile)
                  IconButton(
                    icon: const Icon(Icons.share_rounded, color: PriVaultColors.primary, size: 22),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ShareDialog(file: file, decryptedName: name),
                      );
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded, color: PriVaultColors.textHint),
                  onPressed: () => _showFileActions(context, ref, name),
                ),
              ],
            ),
          ),
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
            if (!(file.isVaultFile))
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
