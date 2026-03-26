// ============================================================
// PriVault – File Viewer Screen
// ============================================================
// Downloads, decrypts, and renders file content by MIME type.
// Displays real comments from Firestore and allows sending.
// ============================================================

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';
import 'package:video_player/video_player.dart';

import 'package:pri_vault/features/files/providers/files_provider.dart';
import 'package:pri_vault/features/sharing/providers/sharing_provider.dart';
import 'package:pri_vault/features/sharing/screens/share_dialog.dart';
import 'package:pri_vault/models/file_metadata.dart';
import 'package:pri_vault/models/share_models.dart';
import 'package:path_provider/path_provider.dart';

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

class _FileViewerScreenState extends ConsumerState<FileViewerScreen>
    with SingleTickerProviderStateMixin {
  Uint8List? _decryptedBytes;
  Uint8List? _resolvedFileKey;
  File? _decryptedTempFile;
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isAudioPlaying = false;
  late final AnimationController _waveController;
  PDFViewController? _pdfController;
  int _pdfPages = 0;
  int _pdfPage = 0;
  bool _isLoading = true;
  String? _error;

  final TextEditingController _commentController = TextEditingController();
  int _commentLength = 0;
  static const int _maxCommentLength = 1000;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _loadFile();
    _commentController.addListener(() {
      setState(() {
        _commentLength = _commentController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    _waveController.dispose();
    final tmp = _decryptedTempFile;
    if (tmp != null && tmp.existsSync()) {
      tmp.deleteSync();
    }
    _commentController.dispose();
    super.dispose();
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
        if (shared.recipientShare.encryptedKey == null) throw Exception('Encrypted key missing');
        final encryptedFileKey = CryptoUtils.fromBase64(shared.recipientShare.encryptedKey!);
        final senderPublicKeyB64 = shared.parentShare.senderPublicKey;
        if (senderPublicKeyB64 != null && senderPublicKeyB64.isNotEmpty) {
          final myKeyPair = await encryptionService.getKeyPairFromPrivateKey(
            CryptoUtils.fromBase64(privKeyB64),
          );
          final sharedSecret = await encryptionService.deriveSharedSecret(
            myKeyPair: myKeyPair,
            theirPublicKeyBytes: CryptoUtils.fromBase64(senderPublicKeyB64),
          );
          fileKey = await encryptionService.decrypt(
            ciphertext: encryptedFileKey,
            key: sharedSecret.sublist(0, 32),
          );
        } else {
          // Legacy fallback for older shares.
          final seedBase64 = await vault.getMasterKeySeed();
          if (seedBase64 == null) throw Exception('Master key not found');
          final masterKey = CryptoUtils.fromBase64(seedBase64);
          fileKey = await encryptionService.decrypt(
            ciphertext: encryptedFileKey,
            key: masterKey,
          );
        }
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
      final tempFile = await _writeTempDecryptedFile(bytes);
      await _prepareMediaControllers(tempFile);

      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      final ownerId = widget.sharedFile?.parentShare.ownerId ?? user?.uid;
      if (user != null && ownerId != null) {
        await ref.read(notificationServiceProvider).notifyFileEvent(
          recipientId: ownerId,
          type: 'file_viewed',
          fileId: widget.file.id,
          fileName: widget.displayName,
          actorId: user.uid,
          actorName: user.email ?? 'User',
        );
      }
      setState(() {
        _resolvedFileKey = fileKey;
        _decryptedBytes = bytes;
        _decryptedTempFile = tempFile;
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
    if (name.endsWith('.mp4') ||
        name.endsWith('.mov') ||
        name.endsWith('.mkv') ||
        name.endsWith('.webm')) {
      return 'video';
    }
    if (name.endsWith('.mp3') ||
        name.endsWith('.wav') ||
        name.endsWith('.aac') ||
        name.endsWith('.m4a') ||
        name.endsWith('.ogg')) {
      return 'audio';
    }
    return 'binary';
  }

  Future<File> _writeTempDecryptedFile(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final safeName = widget.displayName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final file = File('${tempDir.path}/dec_${widget.file.id}_$safeName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _prepareMediaControllers(File file) async {
    final type = _inferType();
    if (type == 'video') {
      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      _videoController!.addListener(() {
        if (mounted) setState(() {});
      });
    } else if (type == 'audio') {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isAudioPlaying = false);
      });
    }
  }

  Future<File> _saveToDownloads(Uint8List bytes) async {
    if (Platform.isAndroid) {
      final storage = await Permission.storage.request();
      if (!storage.isGranted && await Permission.manageExternalStorage.isDenied) {
        final manage = await Permission.manageExternalStorage.request();
        if (!manage.isGranted) throw Exception('Storage permission denied');
      }
      const downloadsDirPath = '/storage/emulated/0/Download';
      final downloadsDir = Directory(downloadsDirPath);
      if (!await downloadsDir.exists()) {
        throw Exception('Downloads folder not available');
      }
      final safeName = widget.displayName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final outputFile = File('$downloadsDirPath/$safeName');
      await outputFile.writeAsBytes(bytes, flush: true);
      return outputFile;
    }
    final fallbackDir = await getApplicationDocumentsDirectory();
    final outputFile = File('${fallbackDir.path}/${widget.displayName}');
    await outputFile.writeAsBytes(bytes, flush: true);
    return outputFile;
  }

  // ───────────────────────────────────────────────
  //  Comment helpers
  // ───────────────────────────────────────────────

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    if (text.length > _maxCommentLength) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment too long (max 1000 characters)')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get display name from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final displayName = userDoc.data()?['displayName'] ??
        userDoc.data()?['username'] ??
        user.email ??
        'User';

    final ownerId = widget.sharedFile?.parentShare.ownerId ?? user.uid;
    if (widget.sharedFile != null &&
        !widget.sharedFile!.parentShare.isActive) {
      throw Exception('Share has expired or was revoked');
    }
    try {
      await FirebaseFirestore.instance
          .collection('comments')
          .add({
        'userId': user.uid,
        'ownerId': ownerId,
        'fileId': widget.file.id,
        'displayName': displayName,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
      if (mounted) setState(() => _commentLength = 0);
      await ref.read(notificationServiceProvider).notifyFileEvent(
        recipientId: ownerId,
        type: 'file_commented',
        fileId: widget.file.id,
        fileName: widget.displayName,
        actorId: user.uid,
        actorName: user.email ?? 'User',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comment failed: $e')),
      );
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${diff.inMinutes == 1 ? "minute" : "minutes"} ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"} ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} ${diff.inDays == 1 ? "day" : "days"} ago';
    }
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PriVaultColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                   GestureDetector(
                     onTap: () => Navigator.of(context).pop(),
                     child: Container(
                       width: 40,
                       height: 40,
                       decoration: BoxDecoration(
                         color: PriVaultColors.surfaceLight,
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: PriVaultColors.cardBorder),
                       ),
                       child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Text(
                       'File Details',
                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
                             fontWeight: FontWeight.w700,
                             color: Colors.white,
                           ),
                     ),
                   ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // File Preview Box
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: PriVaultColors.surfaceLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: PriVaultColors.cardBorder),
                      ),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.indigoAccent.withValues(alpha: 0.1),
                                Colors.cyanAccent.withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: _buildBody(), // Embedded file preview
                        ),
                      ),
                    ),
                    
                    // File Info
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: PriVaultColors.surfaceLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: PriVaultColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.displayName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('File type', _inferType() == 'binary' ? 'Binary File' : '${_inferType().toUpperCase()} Document', context),
                          const SizedBox(height: 12),
                          _buildInfoRow('Size', ((widget.file.sizeBytes) / 1024 / 1024) > 1 
                              ? '${((widget.file.sizeBytes) / 1024 / 1024).toStringAsFixed(1)} MB'
                              : '${((widget.file.sizeBytes) / 1024).toStringAsFixed(1)} KB'
                              , context,),
                          const SizedBox(height: 12),
                          _buildInfoRow('Upload date', widget.file.createdAt != null ? widget.file.createdAt!.toIso8601String().split('T').first : 'Unknown', context),
                          const SizedBox(height: 12),
                          _buildInfoRow('Encryption', 'XChaCha20-Poly1305', context),
                        ],
                      ),
                    ),
                    
                    // Actions Grid
                    Row(
                      children: [
                        if (!(widget.file.isVaultFile)) ...[
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.share_rounded,
                              label: 'Share',
                              color: Colors.indigo.shade400,
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => ShareDialog(
                                    file: widget.file,
                                    decryptedName: widget.displayName,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.download_rounded,
                            label: 'Download',
                            color: Colors.cyan.shade500,
                            onTap: () async {
                              try {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Downloading...')),
                                );
                                final storageRepo = ref.read(storageRepositoryProvider);

                                if (widget.sharedFile != null &&
                                    widget.sharedFile!.parentShare.permission == 'view') {
                                  throw Exception('Download permission denied');
                                }
                                final key = _resolvedFileKey;
                                if (key == null) throw Exception('File key not loaded yet');
                                final bytes = await storageRepo.downloadFile(widget.file, key);
                                final file = await _saveToDownloads(bytes);
                                final user = FirebaseAuth.instance.currentUser;
                                final ownerId = widget.sharedFile?.parentShare.ownerId ?? user?.uid;
                                if (user != null && ownerId != null) {
                                  await ref.read(notificationServiceProvider).notifyFileEvent(
                                    recipientId: ownerId,
                                    type: 'file_downloaded',
                                    fileId: widget.file.id,
                                    fileName: widget.displayName,
                                    actorId: user.uid,
                                    actorName: user.email ?? 'User',
                                  );
                                }

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Saved to ${file.path}')),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Download failed: $e')),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.enhanced_encryption_rounded,
                            label: 'To Vault',
                            color: Colors.purple.shade400,
                            onTap: () async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .collection('files')
                                    .doc(widget.file.id)
                                    .update({'isVaultFile': true});

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Moved to vault')),
                                );
                                Navigator.of(context).pop();
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed: $e')),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.delete_outline_rounded,
                            label: 'Delete',
                            color: Colors.redAccent,
                            isOutlined: true,
                            onTap: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: PriVaultColors.surface,
                                  title: const Text('Delete File?', style: TextStyle(color: Colors.white)),
                                  content: Text(
                                    'Move "${widget.displayName}" to trash?',
                                    style: const TextStyle(color: PriVaultColors.textSecondary),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                try {
                                  await ref.read(storageRepositoryProvider).deleteFile(widget.file);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('File moved to trash')),
                                  );
                                  Navigator.of(context).pop();
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Delete failed: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Comments Section
                    Row(
                      children: [
                        const Icon(Icons.forum_rounded, color: Colors.indigoAccent, size: 20),
                        const SizedBox(width: 8),
                         Text(
                          'Comments',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Real comments from Firestore
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('comments')
                          .where('fileId', isEqualTo: widget.file.id)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            alignment: Alignment.center,
                            child: const Text(
                              'No comments yet',
                              style: TextStyle(color: PriVaultColors.textHint, fontSize: 14),
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: CircularProgressIndicator(color: PriVaultColors.primary),
                            ),
                          );
                        }
                        final comments = [...snapshot.data!.docs];
                        comments.sort((a, b) {
                          final ta = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                          final tb = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                          return (ta?.millisecondsSinceEpoch ?? 0)
                              .compareTo(tb?.millisecondsSinceEpoch ?? 0);
                        });
                        if (comments.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            alignment: Alignment.center,
                            child: const Text(
                              'No comments yet',
                              style: TextStyle(color: PriVaultColors.textHint, fontSize: 14),
                            ),
                          );
                        }
                        return Column(
                          children: comments.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name = data['displayName'] ?? 'User';
                            final text = data['text'] ?? '';
                            final createdAt = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildCommentWidget(name, text, createdAt),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 8),
                    
                    // Comment Input
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: PriVaultColors.surfaceLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: PriVaultColors.cardBorder),
                            ),
                            child: TextField(
                              controller: _commentController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              maxLines: null,
                              decoration: const InputDecoration(
                                hintText: 'Add a comment...',
                                hintStyle: TextStyle(color: PriVaultColors.textHint),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _sendComment,
                          child: Container(
                            width: 48,
                            height: 48,
                             decoration: BoxDecoration(
                              gradient: PriVaultColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    // Character counter
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        '$_commentLength/$_maxCommentLength',
                        style: TextStyle(
                          color: _commentLength > _maxCommentLength
                              ? Colors.redAccent
                              : PriVaultColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: PriVaultColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text('Decryption Failed', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: PriVaultColors.textHint, fontSize: 12)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadFile();
              },
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('Try Again', style: TextStyle(color: Colors.white)),
            ),
          ],
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
            child: Image.memory(bytes, fit: BoxFit.contain),
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
                  color: Colors.white,
                ),
          ),
        );
      case 'video':
        final controller = _videoController;
        if (controller == null || !controller.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }
        final pos = controller.value.position;
        final dur = controller.value.duration;
        final maxMs = dur.inMilliseconds <= 0 ? 1 : dur.inMilliseconds;
        final value = (pos.inMilliseconds.clamp(0, maxMs)) / maxMs;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
            const SizedBox(height: 12),
            Slider(
              value: value.isNaN ? 0 : value.toDouble(),
              onChanged: (v) async {
                await controller.seekTo(
                  Duration(milliseconds: (dur.inMilliseconds * v).toInt()),
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_5_rounded, color: Colors.white),
                  onPressed: () async {
                    final target = pos - const Duration(seconds: 5);
                    await controller.seekTo(target < Duration.zero ? Duration.zero : target);
                  },
                ),
                IconButton(
                  iconSize: 40,
                  icon: Icon(
                    controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      controller.value.isPlaying ? controller.pause() : controller.play();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.forward_5_rounded, color: Colors.white),
                  onPressed: () async {
                    final target = pos + const Duration(seconds: 5);
                    await controller.seekTo(target > dur ? dur : target);
                  },
                ),
              ],
            ),
            Text(
              '${pos.inMinutes}:${(pos.inSeconds % 60).toString().padLeft(2, '0')} / ${dur.inMinutes}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(color: PriVaultColors.textSecondary, fontSize: 12),
            ),
          ],
        );
      case 'audio':
        return AnimatedBuilder(
          animation: _waveController,
          builder: (context, _) {
            final phase = _waveController.value * math.pi * 2;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.audiotrack_rounded, color: Colors.white, size: 60),
                  const SizedBox(height: 12),
                  Text(widget.displayName, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(18, (i) {
                      final h = 10 + (math.sin(phase + (i * 0.35)).abs() * 26);
                      return Container(
                        width: 4,
                        height: _isAudioPlaying ? h : 10,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: PriVaultColors.primary.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  IconButton(
                    iconSize: 44,
                    icon: Icon(
                      _isAudioPlaying ? Icons.pause_circle : Icons.play_circle,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      final player = _audioPlayer;
                      final file = _decryptedTempFile;
                      if (player == null || file == null) return;
                      if (_isAudioPlaying) {
                        await player.pause();
                        if (mounted) setState(() => _isAudioPlaying = false);
                      } else {
                        await player.play(DeviceFileSource(file.path));
                        if (mounted) setState(() => _isAudioPlaying = true);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      case 'pdf':
        final file = _decryptedTempFile;
        if (file == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Expanded(
              child: PDFView(
                filePath: file.path,
                swipeHorizontal: false,
                autoSpacing: true,
                pageFling: true,
                onViewCreated: (controller) => _pdfController = controller,
                onRender: (pages) {
                  if (mounted) setState(() => _pdfPages = pages ?? 0);
                },
                onPageChanged: (page, _) {
                  if (mounted) setState(() => _pdfPage = page ?? 0);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _pdfPage > 0
                        ? () => _pdfController?.setPage(_pdfPage - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                  ),
                  Text(
                    'Page ${_pdfPage + 1}/${_pdfPages == 0 ? 1 : _pdfPages}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  IconButton(
                    onPressed: (_pdfPage + 1) < _pdfPages
                        ? () => _pdfController?.setPage(_pdfPage + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        );
      default:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: PriVaultColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.insert_drive_file_rounded, size: 48, color: PriVaultColors.primary.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 16),
              const Text('PDF / Binary Preview', style: TextStyle(color: PriVaultColors.textHint, fontSize: 13), textAlign: TextAlign.center),
            ],
          ),
        );
    }
  }

  // --- Helper Widgets ---

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
         Text(label, style: const TextStyle(color: PriVaultColors.textSecondary, fontSize: 14)),
         Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap, bool isOutlined = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isOutlined ? color.withValues(alpha: 0.1) : color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isOutlined ? color.withValues(alpha: 0.2) : Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isOutlined ? color : Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isOutlined ? color : Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentWidget(String name, String message, DateTime createdAt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PriVaultColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PriVaultColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: PriVaultColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: PriVaultColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                     Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
                     const SizedBox(width: 8),
                     Text(_formatRelativeTime(createdAt), style: const TextStyle(color: PriVaultColors.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: PriVaultColors.textHint, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

