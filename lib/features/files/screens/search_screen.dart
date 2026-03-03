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
import 'package:pri_vault/features/auth/providers/auth_provider.dart';
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
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search files...',
            border: InputBorder.none,
          ),
          style: Theme.of(context).textTheme.titleMedium,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 80,
              color: PriVaultColors.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Search your encrypted files',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PriVaultColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    if (_results!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No files found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _results!.length,
      itemBuilder: (context, index) {
        final result = _results![index];
        return ListTile(
          leading: const Icon(
            Icons.insert_drive_file_rounded,
            color: PriVaultColors.primary,
          ),
          title: Text(
            result.decryptedName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${(result.file.sizeBytes / 1024).toStringAsFixed(1)} KB',
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FileViewerScreen(
                file: result.file,
                displayName: result.decryptedName,
              ),
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
