// ============================================================
// PriVault – Chat list (WhatsApp-style)
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pri_vault/core/router/app_router.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/services/chat_service.dart';
import 'package:pri_vault/features/files/providers/files_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String? _otherUid(List<dynamic>? members, String me) {
    if (members == null) return null;
    for (final m in members) {
      if (m is String && m != me) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    final chatSvc = ref.watch(chatServiceProvider);
    final firestore = ref.watch(firestoreProvider);
    final notificationSvc = ref.watch(notificationServiceProvider);

    return Scaffold(
      backgroundColor: PriVaultColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chats',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: PriVaultColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push(AppRoutes.addFriend),
                    icon: const Icon(Icons.person_add_rounded, color: PriVaultColors.primary, size: 20),
                    label: const Text('Add Friend', style: TextStyle(color: PriVaultColors.primary)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _search,
                style: const TextStyle(color: PriVaultColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: const TextStyle(color: PriVaultColors.textHint),
                  prefixIcon: const Icon(Icons.search_rounded, color: PriVaultColors.textHint),
                  filled: true,
                  fillColor: PriVaultColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: PriVaultColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: PriVaultColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: PriVaultColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: chatSvc.streamFriendships(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs;
                  final pending = docs.where((d) {
                    final s = d.data()['status'] as String? ?? '';
                    final by = d.data()['requestedBy'] as String?;
                    return s == 'pending' && by != me;
                  }).toList();
                  final outgoing = docs.where((d) {
                    final s = d.data()['status'] as String? ?? '';
                    final by = d.data()['requestedBy'] as String?;
                    return s == 'pending' && by == me;
                  }).toList();
                  final accepted = docs.where((d) {
                    return (d.data()['status'] as String? ?? '') == 'accepted';
                  }).toList();

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      if (pending.isNotEmpty) ...[
                        const Text(
                          'Pending',
                          style: TextStyle(
                            color: PriVaultColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...pending.map((d) => _PendingTile(
                              data: d.data(),
                              onAccept: () async {
                                final requester = d.data()['requestedBy'] as String?;
                                await chatSvc.acceptFriendRequest(d.id);
                                if (requester != null) {
                                  await notificationSvc.notifyFriendRequestAccepted(
                                    requesterUid: requester,
                                  );
                                }
                              },
                              onDecline: () => chatSvc.declineFriendRequest(d.id),
                            ),),
                        const SizedBox(height: 16),
                      ],
                      if (outgoing.isNotEmpty) ...[
                        const Text(
                          'Sent requests',
                          style: TextStyle(
                            color: PriVaultColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...outgoing.map((d) {
                          final other = (d.data()['user1'] == me)
                              ? d.data()['user2']
                              : d.data()['user1'];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: PriVaultColors.surface2,
                              child: Icon(Icons.hourglass_empty_rounded, color: PriVaultColors.textHint),
                            ),
                            title: Text(
                              'Waiting for ${other ?? 'user'}',
                              style: const TextStyle(color: PriVaultColors.textPrimary, fontSize: 14),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                      if (accepted.isNotEmpty) ...[
                        const Text(
                          'Friends',
                          style: TextStyle(
                            color: PriVaultColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...accepted.map((d) {
                          final u1 = d.data()['user1'] as String?;
                          final u2 = d.data()['user2'] as String?;
                          final other = u1 == me ? u2 : u1;
                          if (other == null) return const SizedBox.shrink();
                          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            future: firestore.collection('users').doc(other).get(),
                            builder: (context, userSnap) {
                              final name = userSnap.data?.data()?['displayName'] ??
                                  userSnap.data?.data()?['display_name'] ??
                                  'User';
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: PriVaultColors.primary.withValues(alpha: 0.2),
                                  child: Text(
                                    name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?',
                                    style: const TextStyle(color: PriVaultColors.primary),
                                  ),
                                ),
                                title: Text(
                                  name.toString(),
                                  style: const TextStyle(color: PriVaultColors.textPrimary),
                                ),
                                onTap: () async {
                                  await chatSvc.ensureDirectChat(other);
                                  final cid = ChatService.directChatId(me!, other);
                                  if (context.mounted) {
                                    context.push('${AppRoutes.chatDetail}/$cid');
                                  }
                                },
                              );
                            },
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                      const Text(
                        'Conversations',
                        style: TextStyle(
                          color: PriVaultColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: chatSvc.streamMyChats(),
                        builder: (context, chatSnap) {
                          if (!chatSnap.hasData) {
                            return const SizedBox.shrink();
                          }
                          final chats = chatSnap.data!.docs;
                          if (chats.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'No conversations yet',
                                  style: TextStyle(color: PriVaultColors.textHint),
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: chats.map((doc) {
                              final data = doc.data();
                              final last = data['lastMessage'] as String? ?? '';
                              final members = data['members'] as List<dynamic>?;
                              final other = _otherUid(members, me ?? '');
                              if (other == null) {
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                  leading: const CircleAvatar(
                                    backgroundColor: PriVaultColors.surface2,
                                    child: Icon(Icons.chat_rounded, color: PriVaultColors.primary),
                                  ),
                                  title: const Text('Chat', style: TextStyle(color: PriVaultColors.textPrimary)),
                                  subtitle: Text(
                                    last,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: PriVaultColors.textHint, fontSize: 13),
                                  ),
                                  onTap: () => context.push('${AppRoutes.chatDetail}/${doc.id}'),
                                );
                              }
                              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                future: firestore.collection('users').doc(other).get(),
                                builder: (context, userSnap) {
                                  final name = userSnap.data?.data()?['displayName'] ??
                                      userSnap.data?.data()?['display_name'] ??
                                      'User';
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                    leading: CircleAvatar(
                                      backgroundColor: PriVaultColors.surface2,
                                      child: Text(
                                        name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?',
                                        style: const TextStyle(color: PriVaultColors.primary),
                                      ),
                                    ),
                                    title: Text(
                                      name.toString(),
                                      style: const TextStyle(
                                        color: PriVaultColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      last,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: PriVaultColors.textHint, fontSize: 13),
                                    ),
                                    onTap: () => context.push('${AppRoutes.chatDetail}/${doc.id}'),
                                  );
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _PendingTile({
    required this.data,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    final u1 = data['user1'] as String?;
    final u2 = data['user2'] as String?;
    final other = u1 == me ? u2 : u1;
    return Card(
      color: PriVaultColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: PriVaultColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'User $other wants to connect',
                style: const TextStyle(color: PriVaultColors.textPrimary),
              ),
            ),
            TextButton(
              onPressed: onDecline,
              child: const Text('Decline', style: TextStyle(color: PriVaultColors.error)),
            ),
            TextButton(
              onPressed: onAccept,
              child: const Text('Accept', style: TextStyle(color: PriVaultColors.success)),
            ),
          ],
        ),
      ),
    );
  }
}
