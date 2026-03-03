// ============================================================
// PriVault – Papers Wallet Screen (BR-22)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/core/theme/app_theme.dart';

// --- Provider ---
final papersWalletProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  return await api.getList('/papers-wallet');
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(papersWalletProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Papers Wallet')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: walletAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.credit_card_off_rounded, size: 64, color: PriVaultColors.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('No cards saved', style: TextStyle(color: PriVaultColors.textSecondary)),
                  const SizedBox(height: 8),
                  const Text('Add your ID, student, employee, or bank cards', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final item = items[i] as Map<String, dynamic>;
              final type = item['type'] as String? ?? 'id';
              return Dismissible(
                key: Key(item['id'].toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete, color: Colors.redAccent),
                ),
                confirmDismiss: (dir) => showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Card'),
                    content: const Text('This card data will be permanently removed.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                    ],
                  ),
                ),
                onDismissed: (_) async {
                  final api = ref.read(apiClientProvider);
                  await api.delete('/papers-wallet/${item['id']}');
                  ref.invalidate(papersWalletProvider);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _typeColor(type).withValues(alpha: 0.15),
                        PriVaultColors.surfaceLight,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _typeColor(type).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: _typeColor(type).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_typeIcons[type] ?? Icons.badge, color: _typeColor(type)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_typeLabels[type] ?? type, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('Encrypted', style: TextStyle(color: PriVaultColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(Icons.lock_rounded, color: PriVaultColors.textSecondary, size: 18),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _typeColor(String type) => switch (type) {
    'id' => Colors.blue,
    'student_card' => Colors.green,
    'employee_card' => Colors.orange,
    'bank_card' => Colors.purple,
    _ => PriVaultColors.primary,
  };

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
                  final api = ref.read(apiClientProvider);
                  await api.post('/papers-wallet', body: {
                    'type': selectedType,
                    'encrypted_data': dataCtrl.text.trim(),
                  });
                  ref.invalidate(papersWalletProvider);
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
}
