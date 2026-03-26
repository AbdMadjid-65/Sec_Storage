// ============================================================
// PriVault – Search Screen
// ============================================================
// Client-side encrypted filename search. Decrypts all file names
// in-memory and filters by the query string.
// ============================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';

import 'package:pri_vault/features/files/providers/files_provider.dart';
import 'package:pri_vault/features/sharing/providers/sharing_provider.dart';
import 'package:pri_vault/features/files/screens/file_detail_screen.dart';
import 'package:pri_vault/models/file_metadata.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  List<_SearchResult>? _results;
  bool _isSearching = false;
  Uint8List? _masterKey;

  @override
  void initState() {
    super.initState();
    _loadMasterKey();
  }

  Future<void> _loadMasterKey() async {
    final vault = ref.read(vaultServiceProvider);
    final seedBase64 = await vault.getMasterKeySeed();
    if (seedBase64 != null) {
      _masterKey = CryptoUtils.fromBase64(seedBase64);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final repo = ref.read(storageRepositoryProvider);
      final encryption = ref.read(encryptionServiceProvider);
      final key = _masterKey;
      if (key == null) {
        setState(() {
          _isSearching = false;
          _results = [];
        });
        return;
      }

      // Fetch ALL non-deleted files
      final allFiles = await repo.getFiles();
      final results = <_SearchResult>[];

      for (final file in allFiles) {
        String decryptedName;
        try {
          if (file.encryptedName.isEmpty) {
            decryptedName = 'Untitled File';
          } else {
            final decryptedBytes = await encryption.decrypt(
              ciphertext: CryptoUtils.fromBase64(file.encryptedName),
              key: key,
            );
            decryptedName = String.fromCharCodes(decryptedBytes);
          }
        } catch (_) {
          decryptedName = 'Encrypted File';
        }

        if (decryptedName.toLowerCase().contains(query.toLowerCase())) {
          results.add(_SearchResult(file: file, decryptedName: decryptedName));
        }
      }

      if (!mounted) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search files...',
            hintStyle: TextStyle(color: PriVaultColors.textHint),
            border: InputBorder.none,
          ),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          onChanged: (query) {
            // Debounced search
            Future.delayed(const Duration(milliseconds: 400), () {
              if (_searchController.text == query) {
                _performSearch(query);
              }
            });
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _searchController.clear();
                setState(() => _results = null);
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results == null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: PriVaultColors.surfaceLight,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: PriVaultColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search_rounded, size: 48, color: PriVaultColors.primary.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 16),
              Text('Search Files', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('Search through your securely encrypted files by name.', style: TextStyle(color: PriVaultColors.textHint), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (_results!.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: PriVaultColors.surfaceLight,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search_off_rounded, size: 48, color: Colors.redAccent.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 16),
              Text('No Results', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('No files match "${_searchController.text}".', style: const TextStyle(color: PriVaultColors.textHint), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _results!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final result = _results![index];
        return InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FileViewerScreen(
                file: result.file,
                displayName: result.decryptedName,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PriVaultColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PriVaultColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.insert_drive_file_rounded, color: PriVaultColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.decryptedName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(result.file.sizeBytes / 1024).toStringAsFixed(1)} KB',
                        style: const TextStyle(color: PriVaultColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: PriVaultColors.background, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_rounded, color: PriVaultColors.primary, size: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchResult {
  final FileMetadata file;
  final String decryptedName;

  const _SearchResult({required this.file, required this.decryptedName});
}
