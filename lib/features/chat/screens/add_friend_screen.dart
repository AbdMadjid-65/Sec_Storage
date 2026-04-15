// ============================================================
// PriVault – Add friend by username
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/services/chat_service.dart';
import 'package:pri_vault/features/files/providers/files_provider.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _query = TextEditingController();
  bool _searching = false;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _results = [];

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    try {
      final svc = ref.read(chatServiceProvider);
      var r = await svc.searchUsersByDisplayName(q);
      if (r.isEmpty) {
        final alt = await FirebaseFirestore.instance
            .collection('users')
            .where('display_name', isEqualTo: q)
            .limit(20)
            .get();
        r = alt.docs.where((d) => d.id != FirebaseAuth.instance.currentUser?.uid).toList();
      }
      setState(() => _results = r);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _add(String uid, String displayName) async {
    final svc = ref.read(chatServiceProvider);
    final n = ref.read(notificationServiceProvider);
    final me = FirebaseAuth.instance.currentUser;
    await svc.sendFriendRequest(uid);
    await n.notifyFriendRequest(
      recipientId: uid,
      actorId: me?.uid ?? '',
      actorName: me?.displayName ?? me?.email ?? 'Someone',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent')),
      );
      context.pop();
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PriVaultColors.background,
      appBar: AppBar(
        backgroundColor: PriVaultColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: PriVaultColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add Friend', style: TextStyle(color: PriVaultColors.textPrimary)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _query,
              style: const TextStyle(color: PriVaultColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Username (exact match)',
                labelStyle: const TextStyle(color: PriVaultColors.textSecondary),
                filled: true,
                fillColor: PriVaultColors.surface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _searching ? null : _search,
              style: FilledButton.styleFrom(
                backgroundColor: PriVaultColors.primary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _searching
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Search'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, i) {
                  final doc = _results[i];
                  final data = doc.data();
                  final name = data['displayName'] ?? data['display_name'] ?? 'User';
                  final photo = data['photoUrl'] ?? data['photoURL'];
                  return Card(
                    color: PriVaultColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: PriVaultColors.cardBorder),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: photo is String && photo.isNotEmpty ? NetworkImage(photo) : null,
                        child: photo is String && photo.isEmpty
                            ? Text(name.toString()[0].toUpperCase())
                            : (photo == null ? Text(name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?') : null),
                      ),
                      title: Text(name.toString(), style: const TextStyle(color: PriVaultColors.textPrimary)),
                      subtitle: Text('@$name', style: const TextStyle(color: PriVaultColors.textHint, fontSize: 12)),
                      trailing: TextButton(
                        onPressed: () => _add(doc.id, name.toString()),
                        child: const Text('Add', style: TextStyle(color: PriVaultColors.primary)),
                      ),
                    ),
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
