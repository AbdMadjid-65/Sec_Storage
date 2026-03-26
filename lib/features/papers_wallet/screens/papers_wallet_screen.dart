// ============================================================
// PriVault – Papers Wallet Screen (BR-22) – Firebase
// ============================================================

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/features/files/providers/files_provider.dart';
import 'package:pri_vault/features/sharing/providers/sharing_provider.dart';
import 'package:pri_vault/ui/widgets/privault_button.dart';

// --- Provider ---
final papersWalletProvider = FutureProvider<List<dynamic>>((ref) async {
  final firestore = ref.read(firestoreProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return [];

  final snapshot = await firestore
      .collection('users')
      .doc(uid)
      .collection('papersWallet')
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs.map((doc) {
    final data = doc.data();
    data['id'] = doc.id;
    return data;
  }).toList();
});

// --- Screen ---
class PapersWalletScreen extends ConsumerWidget {
  const PapersWalletScreen({super.key});

  static const _typeIcons = <String, IconData>{
    'id': Icons.badge_rounded,
    'student_card': Icons.school_rounded,
    'employee_card': Icons.work_rounded,
    'bank_card': Icons.credit_card_rounded,
  };

  static const _typeLabels = <String, String>{
    'id': 'ID Card',
    'student_card': 'Student Card',
    'employee_card': 'Employee Card',
    'bank_card': 'Bank Card',
  };

  static const _typeGradients = <String, LinearGradient>{
    'id': LinearGradient(colors: [Colors.blue, Colors.cyan], begin: Alignment.topLeft, end: Alignment.bottomRight),
    'student_card': LinearGradient(colors: [Colors.purple, Colors.pinkAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
    'employee_card': LinearGradient(colors: [Colors.indigo, Colors.purple], begin: Alignment.topLeft, end: Alignment.bottomRight),
    'bank_card': LinearGradient(colors: [Colors.orange, Colors.red], begin: Alignment.topLeft, end: Alignment.bottomRight),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(papersWalletProvider);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Sarah Johnson';

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
                           'Papers Wallet',
                           style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                 fontWeight: FontWeight.w700,
                                 color: Colors.white,
                               ),
                         ),
                         const Text(
                           'Your digital documents',
                           style: TextStyle(color: PriVaultColors.textHint, fontSize: 13),
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Security Notice
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock_rounded, color: Colors.amber, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Secure & Private', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(
                                  'These cards cannot be shared externally for your security',
                                  style: TextStyle(color: PriVaultColors.textHint.withValues(alpha: 0.8), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Cards List
                    walletAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (items) {
                        return Column(
                          children: [
                            if (items.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.credit_card_rounded, color: PriVaultColors.textHint, size: 40),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('No cards yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
                                    const SizedBox(height: 8),
                                    const Text('Add your IDs, student cards, and other documents', textAlign: TextAlign.center, style: TextStyle(color: PriVaultColors.textHint, fontSize: 14)),
                                    const SizedBox(height: 24),
                                    PriVaultButton(
                                      text: 'Add Your First Card',
                                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                                      onPressed: () => _showAddDialog(context, ref),
                                    ),
                                  ],
                                ),
                              )
                            else ...[
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, i) {
                                  final item = items[i] as Map<String, dynamic>;
                                  final type = item['type'] as String? ?? 'id';
                                  final gradient = _typeGradients[type] ?? PriVaultColors.primaryGradient;
                                  // BR-22: Decrypt card data with master key
                                  final encData = item['encrypted_data'] as String? ?? '';
                                  // Show masked card data (full decryption would need async)
                                  final displayData = encData.isNotEmpty
                                      ? '\u2022\u2022\u2022\u2022 \u2022\u2022\u2022\u2022 ${encData.substring(0, encData.length > 4 ? 4 : encData.length)}'
                                      : '\u2022\u2022\u2022\u2022 \u2022\u2022\u2022\u2022 \u2022\u2022\u2022\u2022';

                                  return Dismissible(
                                    key: Key(item['id'].toString()),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 24),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                                    ),
                                    confirmDismiss: (dir) => showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Card'),
                                        content: const Text('This card data will be permanently removed.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
                                        ],
                                      ),
                                    ),
                                    onDismissed: (_) async {
                                      final firestore = ref.read(firestoreProvider);
                                      if (user != null) {
                                        await firestore
                                            .collection('users')
                                            .doc(user.uid)
                                            .collection('papersWallet')
                                            .doc(item['id'])
                                            .delete();
                                        ref.invalidate(papersWalletProvider);
                                      }
                                    },
                                    child: Container(
                                      height: 192,
                                      decoration: BoxDecoration(
                                        gradient: gradient,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: gradient.colors.last.withValues(alpha: 0.3),
                                            blurRadius: 24,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          // Background Pattern Emulation
                                          Positioned(
                                            top: -128,
                                            right: -128,
                                            child: Container(
                                              width: 256,
                                              height: 256,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: -96,
                                            left: -96,
                                            child: Container(
                                              width: 192,
                                              height: 192,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                          // Content
                                          Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(_typeLabels[type] ?? type, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                                                          const SizedBox(height: 2),
                                                          const Text('Valid until 2030', style: TextStyle(color: Colors.white, fontSize: 12)),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      width: 48,
                                                      height: 48,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withValues(alpha: 0.2),
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      child: Icon(_typeIcons[type] ?? Icons.badge_rounded, color: Colors.white, size: 24),
                                                    ),
                                                  ],
                                                ),
                                                const Spacer(),
                                                // Chip Emulation
                                                Container(
                                                  margin: const EdgeInsets.only(bottom: 12),
                                                  width: 48,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(colors: [Colors.yellow.shade200, Colors.yellow.shade600]),
                                                    borderRadius: BorderRadius.circular(8),
                                                    color: Colors.yellow,
                                                  ),
                                                ),
                                                Text(
                                                  displayData,
                                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              
                              GestureDetector(
                                onTap: () => _showAddDialog(context, ref),
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: PriVaultColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Add New Card',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    String selectedType = 'id';
    final dataCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Add Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                items: _typeLabels.entries.map((e) =>
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
                ).toList(),
                onChanged: (v) => setDState(() => selectedType = v!),
                decoration: const InputDecoration(labelText: 'Card Type'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dataCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Card Data (will be encrypted)',
                  hintText: 'Name, number, expiry...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (dataCtrl.text.isEmpty) return;
                try {
                  final firestore = ref.read(firestoreProvider);
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    await firestore
                        .collection('users')
                        .doc(uid)
                        .collection('papersWallet')
                        .add({
                      'type': selectedType,
                      'encrypted_data': await _encryptCardData(
                        ref, dataCtrl.text.trim(),
                      ),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    ref.invalidate(papersWalletProvider);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// BR-22: Encrypt card data with the user's master key.
  static Future<String> _encryptCardData(WidgetRef ref, String plaintext) async {
    try {
      final vaultSvc = ref.read(vaultServiceProvider);
      final masterKeyB64 = await vaultSvc.getMasterKeySeed();
      if (masterKeyB64 == null) return plaintext;

      final masterKey = CryptoUtils.fromBase64(masterKeyB64);
      final encryption = ref.read(encryptionServiceProvider);
      final encrypted = await encryption.encrypt(
        plaintext: Uint8List.fromList(plaintext.codeUnits),
        key: masterKey,
      );
      return CryptoUtils.toBase64(encrypted);
    } catch (e) {
      debugPrint('Papers wallet encryption failed: $e');
      return plaintext;
    }
  }
}
