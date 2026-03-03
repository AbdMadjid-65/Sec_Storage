// ============================================================
// PriVault – Audit Logs Screen (BR-16, BR-17, BR-COMP-13)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// --- Provider ---
final auditLogsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  return await api.getList('/audit-logs');
});

// --- Screen ---
class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
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
        ],
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('No audit logs yet', style: TextStyle(color: PriVaultColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: PriVaultColors.divider),
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
      final api = ref.read(apiClientProvider);
      // For personal logs, we just download them as CSV
      final profile = await api.get('/profiles/me');
      final companies = (profile['companies'] as List?) ?? [];

      if (companies.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV export is available for company accounts')),
        );
        return;
      }

      final companyId = companies.first['id'];
      final csvData = await api.downloadCsv('/audit-logs/export?company_id=$companyId');

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
    final ipAddress = log['ip_address'] as String? ?? '';
    final deviceType = log['device_type'] as String? ?? '';

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: _actionColor(action).withValues(alpha: 0.15),
        child: Icon(_actionIcon(action), size: 16, color: _actionColor(action)),
      ),
      title: Text(
        _formatAction(action),
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
      ),
      subtitle: Text(
        '${email.isNotEmpty ? '$email · ' : ''}${_formatTime(createdAt)}${ipAddress.isNotEmpty ? ' · $ipAddress' : ''}${deviceType.isNotEmpty ? ' · $deviceType' : ''}',
        style: const TextStyle(fontSize: 11, color: PriVaultColors.textSecondary),
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
    if (action.contains('login')) return Colors.green;
    if (action.contains('upload')) return Colors.blue;
    if (action.contains('download')) return Colors.teal;
    if (action.contains('delete')) return Colors.red;
    if (action.contains('share')) return Colors.purple;
    if (action.contains('vault')) return Colors.amber;
    return PriVaultColors.primary;
  }
}
