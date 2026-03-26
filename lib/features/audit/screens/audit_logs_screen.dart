// ============================================================
// PriVault – Audit Logs Screen (BR-16, BR-17, BR-COMP-13)
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

// --- Provider ---
final auditLogsProvider = FutureProvider<List<dynamic>>((ref) async {
  final firestore = ref.read(firestoreProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return [];

  final snapshot = await firestore
      .collection('auditLogs')
      .where('userId', isEqualTo: uid)
      .orderBy('timestamp', descending: true)
      .limit(200)
      .get();

  return snapshot.docs.map((doc) {
    final data = doc.data();
    data['id'] = doc.id;
    // Convert Timestamp fields to strings
    if (data['timestamp'] is Timestamp) {
      data['created_at'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
    }
    return data;
  }).toList();
});

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Audit Logs',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_rounded),
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(auditLogsProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: PriVaultColors.surfaceLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: PriVaultColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.history_rounded, size: 48, color: PriVaultColors.primary.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 16),
                    Text('No Activity Yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('Audit logs will appear here', style: TextStyle(color: PriVaultColors.textHint)),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final log = logs[i] as Map<String, dynamic>;
              return _AuditLogTile(log: log);
            },
          );
        },
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    try {
      final logsAsync = ref.read(auditLogsProvider);
      final logs = logsAsync.valueOrNull ?? [];

      if (logs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No logs to export')),
          );
        }
        return;
      }

      // Generate CSV from Firestore data
      final rows = <List<String>>[
        ['Action', 'Email', 'Timestamp', 'IP Address', 'Device Type'],
        ...logs.map((log) {
          final l = log as Map<String, dynamic>;
          return [
            l['action']?.toString() ?? '',
            l['email']?.toString() ?? '',
            l['created_at']?.toString() ?? '',
            l['ipAddress']?.toString() ?? '',
            l['deviceType']?.toString() ?? '',
          ];
        }),
      ];

      final csvData = const ListToCsvConverter().convert(rows);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/audit_logs.csv');
      await file.writeAsString(csvData);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'PriVault Audit Logs',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}

class _AuditLogTile extends StatelessWidget {
  final Map<String, dynamic> log;
  const _AuditLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final action = log['action'] as String? ?? '';
    final email = log['email'] as String? ?? '';
    final createdAt = log['created_at'] as String? ?? '';
    final ipAddress = log['ipAddress'] as String? ?? '';
    final deviceType = log['deviceType'] as String? ?? '';
    final color = _actionColor(action);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PriVaultColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_actionIcon(action), size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatAction(action),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                if (email.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(email, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ),
                Row(
                  children: [
                    Text(_formatTime(createdAt), style: const TextStyle(fontSize: 11, color: PriVaultColors.textSecondary)),
                    if (ipAddress.isNotEmpty) ...[
                      const Text(' · ', style: TextStyle(color: PriVaultColors.textHint)),
                      Text(ipAddress, style: const TextStyle(fontSize: 11, color: PriVaultColors.textHint)),
                    ],
                  ],
                ),
                if (deviceType.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(deviceType, style: const TextStyle(fontSize: 10, color: PriVaultColors.textHint)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAction(String action) {
    return action.replaceAll('.', ' → ').replaceAll('_', ' ');
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  IconData _actionIcon(String action) {
    if (action.contains('login')) return Icons.login_rounded;
    if (action.contains('upload')) return Icons.upload_rounded;
    if (action.contains('download')) return Icons.download_rounded;
    if (action.contains('delete')) return Icons.delete_rounded;
    if (action.contains('share')) return Icons.share_rounded;
    if (action.contains('vault')) return Icons.lock_rounded;
    if (action.contains('company')) return Icons.business_rounded;
    return Icons.history_rounded;
  }

  Color _actionColor(String action) {
    if (action.contains('login')) return Colors.greenAccent;
    if (action.contains('upload')) return Colors.blueAccent;
    if (action.contains('download')) return Colors.tealAccent;
    if (action.contains('delete')) return Colors.redAccent;
    if (action.contains('share')) return Colors.purpleAccent;
    if (action.contains('vault')) return Colors.amberAccent;
    return PriVaultColors.primary;
  }
}
