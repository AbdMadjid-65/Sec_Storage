// ============================================================
// PriVault – File Comments Screen (BR-COM-01–03)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/core/theme/app_theme.dart';

// --- Provider ---
final fileCommentsProvider =
    FutureProvider.family<List<dynamic>, String>((ref, fileId) async {
  final api = ref.read(apiClientProvider);
  return await api.getList('/files/$fileId/comments');
});

// --- Screen ---
class FileCommentsSheet extends ConsumerStatefulWidget {
  final String fileId;
  final String fileName;

  const FileCommentsSheet({super.key, required this.fileId, required this.fileName});

  @override
  ConsumerState<FileCommentsSheet> createState() => _FileCommentsSheetState();
}

class _FileCommentsSheetState extends ConsumerState<FileCommentsSheet> {
  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    // BR-COM-03: Max 750 chars
    if (text.length > 750) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment must be 750 characters or less')),
      );
      return;
    }

    // BR-COM-02: No external links
    if (RegExp(r'https?://').hasMatch(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('External links are not allowed')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/files/${widget.fileId}/comments', body: {'content': text});
      _commentController.clear();
      ref.invalidate(fileCommentsProvider(widget.fileId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(fileCommentsProvider(widget.fileId));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: PriVaultColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: PriVaultColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Comments: ${widget.fileName}',
                  style: Theme.of(context).textTheme.titleMedium),
            ),

            // Comments list
            Expanded(
              child: commentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (comments) {
                  if (comments.isEmpty) {
                    return const Center(
                      child: Text('No comments yet', style: TextStyle(color: PriVaultColors.textSecondary)),
                    );
                  }
                  return ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: comments.length,
                    itemBuilder: (context, i) {
                      final c = comments[i] as Map<String, dynamic>;
                      return _CommentBubble(comment: c);
                    },
                  );
                },
              ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: PriVaultColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      maxLength: 750,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isSending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: PriVaultColors.primary),
                    onPressed: _isSending ? null : _sendComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final Map<String, dynamic> comment;
  const _CommentBubble({required this.comment});

  @override
  Widget build(BuildContext context) {
    final email = comment['email'] as String? ?? '';
    final content = comment['content'] as String? ?? '';
    final createdAt = comment['created_at'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PriVaultColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(email, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: PriVaultColors.primary)),
              Text(_formatTime(createdAt), style: const TextStyle(fontSize: 10, color: PriVaultColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
