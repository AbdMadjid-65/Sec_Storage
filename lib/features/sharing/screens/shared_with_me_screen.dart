// ============================================================
// PriVault – Shared With Me Screen
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/features/files/screens/file_detail_screen.dart';
import 'package:pri_vault/features/sharing/providers/sharing_provider.dart';
import 'package:pri_vault/models/share_models.dart';

class SharedWithMeScreen extends ConsumerWidget {
  const SharedWithMeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sharedWithMeLiveProvider);

    return async.when(
      data: (files) {
        if (files.isEmpty) {
          return Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: PriVaultColors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: PriVaultColors.cardBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color:
                          PriVaultColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people_alt_rounded,
                        size: 32, color: PriVaultColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text('No files shared with you',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 8),
                  const Text(
                    'Files others share with you will appear here.',
                    style: TextStyle(
                        color: PriVaultColors.textHint, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding:
              const EdgeInsets.fromLTRB(24, 0, 24, 100),
          itemCount: files.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) =>
              _SharedFileCard(shared: files[i]),
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.white))),
    );
  }
}

class _SharedFileCard extends StatelessWidget {
  final SharedFile shared;
  const _SharedFileCard({required this.shared});

  @override
  Widget build(BuildContext context) {
    final share = shared.parentShare;
    final file = shared.file;
    final canDownload = share.permission == 'download';
    final mimeType = file.mimeType;

    final (icon, iconColor) = _iconForMime(mimeType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PriVaultColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PriVaultColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── File info ───────────────────────────────────
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatSize(file.sizeBytes),
                      style: const TextStyle(
                          color: PriVaultColors.textHint,
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Permission badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: canDownload
                      ? Colors.blueAccent.withValues(alpha: 0.12)
                      : PriVaultColors.primary
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      canDownload
                          ? Icons.download_outlined
                          : Icons.visibility_outlined,
                      size: 12,
                      color: canDownload
                          ? Colors.blueAccent
                          : PriVaultColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      canDownload ? 'Download' : 'View only',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: canDownload
                              ? Colors.blueAccent
                              : PriVaultColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Shared by + expiry ───────────────────────────
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 13, color: PriVaultColors.textHint),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  shared.ownerEmail ?? share.ownerId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: PriVaultColors.textSecondary,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.schedule_rounded,
                  size: 13, color: PriVaultColors.textHint),
              const SizedBox(width: 4),
              Text(
                share.expiresAt == null
                    ? 'No expiry'
                    : 'Expires ${_fmt(share.expiresAt)}',
                style: const TextStyle(
                    color: PriVaultColors.textHint, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Action buttons ───────────────────────────────
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Row(
              children: [
                // View button — always available
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.visibility_outlined,
                    label: 'View',
                    color: PriVaultColors.primary,
                    onTap: () => _onView(context, shared),
                  ),
                ),
                // Download button — only if permission allows
                if (canDownload) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.download_rounded,
                      label: 'Download',
                      color: Colors.blueAccent,
                      onTap: () => _onDownload(context, shared),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onView(BuildContext context, SharedFile shared) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FileViewerScreen(
          file: shared.file,
          displayName: shared.file.name,
          sharedFile: shared,
        ),
      ),
    );
  }

  void _onDownload(BuildContext context, SharedFile shared) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FileViewerScreen(
          file: shared.file,
          displayName: shared.file.name,
          sharedFile: shared,
        ),
      ),
    );
  }

  (IconData, Color) _iconForMime(String mime) {
    if (mime.startsWith('image/')) {
      return (Icons.image_outlined, Colors.pinkAccent);
    } else if (mime.startsWith('video/')) {
      return (Icons.videocam_outlined, Colors.redAccent);
    } else if (mime.startsWith('audio/')) {
      return (Icons.headphones_outlined, Colors.purpleAccent);
    } else if (mime == 'application/pdf') {
      return (Icons.picture_as_pdf_outlined, Colors.redAccent);
    } else if (mime.contains('word') || mime.contains('document')) {
      return (Icons.description_outlined, Colors.blueAccent);
    } else if (mime.contains('sheet') || mime.contains('excel')) {
      return (Icons.table_chart_outlined, Colors.greenAccent);
    }
    return (Icons.insert_drive_file_outlined, PriVaultColors.primary);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}