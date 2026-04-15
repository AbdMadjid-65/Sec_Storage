// ============================================================
// PriVault – Chat detail (encrypted messages)
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/services/chat_service.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatDetailScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    final chatSvc = ref.watch(chatServiceProvider);

    return Scaffold(
      backgroundColor: PriVaultColors.background,
      appBar: AppBar(
        backgroundColor: PriVaultColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: PriVaultColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Chat', style: TextStyle(color: PriVaultColors.textPrimary)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: chatSvc.streamMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: PriVaultColors.error)));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scroll.hasClients) {
                    _scroll.jumpTo(_scroll.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data();
                    final sender = data['senderId'] as String? ?? '';
                    final enc = data['text'] as String? ?? '';
                    final mine = sender == me;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: FutureBuilder<String>(
                        future: chatSvc.decryptText(enc),
                        builder: (context, snap) {
                          final text = snap.data ?? (snap.hasError ? '…' : '…');
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                            decoration: BoxDecoration(
                              gradient: mine ? PriVaultColors.primaryGradient : null,
                              color: mine ? null : PriVaultColors.surface,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(mine ? 16 : 4),
                                bottomRight: Radius.circular(mine ? 4 : 16),
                              ),
                              border: mine ? null : Border.all(color: PriVaultColors.cardBorder),
                            ),
                            child: Text(
                              text,
                              style: TextStyle(
                                color: mine ? Colors.white : PriVaultColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(color: PriVaultColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Message',
                        hintStyle: const TextStyle(color: PriVaultColors.textHint),
                        filled: true,
                        fillColor: PriVaultColors.surface2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: PriVaultColors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: PriVaultColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: PriVaultColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: PriVaultColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final t = _controller.text.trim();
                      if (t.isEmpty) return;
                      _controller.clear();
                      await chatSvc.sendMessage(chatId: widget.chatId, plainText: t);
                    },
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
