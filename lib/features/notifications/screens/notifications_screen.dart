import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/features/files/providers/files_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(notificationServiceProvider).streamMyNotifications();
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
                    onTap: () => context.pop(),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                        ),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: stream,
                          builder: (context, snapshot) {
                            final unread = snapshot.hasData
                                ? snapshot.data!.docs
                                    .where((d) => (d.data()['isRead'] as bool? ?? false) == false)
                                    .length
                                : 0;
                            return Text(
                              '$unread unread notifications',
                              style: const TextStyle(color: PriVaultColors.textHint, fontSize: 13),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(notificationServiceProvider).markAllRead(),
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(
                        color: Colors.indigoAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Notifications List
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No notifications yet',
                        style: TextStyle(color: PriVaultColors.textHint),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = docs[index].data();
                      final isUnread = !(item['isRead'] as bool? ?? false);
                      final type = item['type'] as String? ?? 'file_viewed';
                      final fileName = item['fileName'] as String? ?? 'file';
                      final actor = (item['actor'] as Map<String, dynamic>? ?? const {})['name'] as String? ?? 'Someone';
                      final ts = item['timestamp'] as Timestamp?;
                      final time = _formatTime(ts?.toDate());
                      final meta = _meta(type);
                      return Container(
                    decoration: BoxDecoration(
                      color: isUnread ? PriVaultColors.surfaceLight : const Color(0xFF111118),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isUnread 
                          ? Colors.indigoAccent.withValues(alpha: 0.2) 
                          : PriVaultColors.cardBorder,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: meta.$3.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                meta.$1,
                                color: meta.$2,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meta.$4,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$actor ${meta.$5} "$fileName"',
                                    style: const TextStyle(
                                      color: PriVaultColors.textHint,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    time,
                                    style: const TextStyle(
                                      color: PriVaultColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Room for unread dot
                            if (isUnread) const SizedBox(width: 12),
                          ],
                        ),
                        if (isUnread)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.indigoAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
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
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'now';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  (IconData, Color, Color, String, String) _meta(String type) {
    switch (type) {
      case 'file_downloaded':
        return (Icons.download_rounded, Colors.cyanAccent, Colors.cyanAccent, 'File Downloaded', 'downloaded');
      case 'file_commented':
        return (Icons.comment_rounded, Colors.orangeAccent, Colors.orangeAccent, 'File Commented', 'commented on');
      case 'file_shared_with_user':
        return (Icons.share_rounded, Colors.indigoAccent, Colors.indigoAccent, 'File Shared', 'shared');
      case 'file_viewed':
      default:
        return (Icons.visibility_rounded, Colors.greenAccent, Colors.greenAccent, 'File Viewed', 'viewed');
    }
  }
}
