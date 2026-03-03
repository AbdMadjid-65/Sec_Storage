// ============================================================
// PriVault – Company Management Screen (BR-18–20, BR-COMP-*)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/core/theme/app_theme.dart';

// --- Providers ---

final userCompaniesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final profile = await api.get('/profiles/me');
  return (profile['companies'] as List?) ?? [];
});

final companyDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, companyId) async {
  final api = ref.read(apiClientProvider);
  return await api.get('/companies/$companyId');
});

// --- Screen ---

class CompanyScreen extends ConsumerStatefulWidget {
  const CompanyScreen({super.key});

  @override
  ConsumerState<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends ConsumerState<CompanyScreen> {
  String? _selectedCompanyId;

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(userCompaniesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded),
            tooltip: 'Create Company',
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: companiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (companies) {
          if (companies.isEmpty && _selectedCompanyId == null) {
            return _EmptyCompanyView(onCreate: _showCreateDialog);
          }
          if (_selectedCompanyId != null) {
            return _CompanyDetailView(
              companyId: _selectedCompanyId!,
              onBack: () => setState(() => _selectedCompanyId = null),
            );
          }
          return _CompanyListView(
            companies: companies,
            onSelect: (id) => setState(() => _selectedCompanyId = id),
          );
        },
      ),
    );
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Company'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Company Name')),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Official Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final api = ref.read(apiClientProvider);
                await api.post('/companies', body: {
                  'name': nameCtrl.text.trim(),
                  'official_email': emailCtrl.text.trim(),
                });
                ref.invalidate(userCompaniesProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCompanyView extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyCompanyView({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_rounded, size: 64, color: PriVaultColors.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('No companies yet', style: TextStyle(color: PriVaultColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Create Company'),
          ),
        ],
      ),
    );
  }
}

class _CompanyListView extends StatelessWidget {
  final List<dynamic> companies;
  final ValueChanged<String> onSelect;
  const _CompanyListView({required this.companies, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: companies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final c = companies[i] as Map<String, dynamic>;
        return Card(
          color: PriVaultColors.surfaceLight,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: PriVaultColors.primary.withValues(alpha: 0.15),
              child: const Icon(Icons.business, color: PriVaultColors.primary),
            ),
            title: Text(c['name'] ?? 'Company'),
            subtitle: Text('Role: ${c['role'] ?? 'member'}', style: const TextStyle(color: PriVaultColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onSelect(c['id'].toString()),
          ),
        );
      },
    );
  }
}

class _CompanyDetailView extends ConsumerWidget {
  final String companyId;
  final VoidCallback onBack;
  const _CompanyDetailView({required this.companyId, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(companyDetailProvider(companyId));

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        final company = data['company'] as Map<String, dynamic>? ?? {};
        final members = (data['members'] as List?) ?? [];
        final teams = (data['teams'] as List?) ?? [];
        final role = data['current_role'] as String? ?? 'viewer';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Back button
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('All Companies'),
              ),
            ),

            // Company header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: PriVaultColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PriVaultColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(company['name'] ?? 'Company', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(company['official_email'] ?? '', style: const TextStyle(color: PriVaultColors.textSecondary)),
                  const SizedBox(height: 8),
                  _RoleBadge(role: role),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Members
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Members (${members.length})', style: Theme.of(context).textTheme.titleMedium),
                if (['owner', 'admin'].contains(role))
                  IconButton(
                    icon: const Icon(Icons.person_add_rounded, size: 20),
                    onPressed: () => _showAddMemberDialog(context, ref),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...members.map((m) {
              final member = m as Map<String, dynamic>;
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: _roleColor(member['role']).withValues(alpha: 0.2),
                  child: Text((member['email'] ?? '?')[0].toUpperCase(), style: TextStyle(color: _roleColor(member['role']), fontSize: 14)),
                ),
                title: Text(member['display_name'] ?? member['email'] ?? 'Unknown'),
                subtitle: Text(member['role'] ?? 'member', style: const TextStyle(fontSize: 11)),
              );
            }),

            const SizedBox(height: 20),

            // Teams
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Teams (${teams.length})', style: Theme.of(context).textTheme.titleMedium),
                if (['owner', 'admin', 'manager'].contains(role))
                  IconButton(
                    icon: const Icon(Icons.group_add_rounded, size: 20),
                    onPressed: () => _showCreateTeamDialog(context, ref),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (teams.isEmpty)
              const Text('No teams yet', style: TextStyle(color: PriVaultColors.textSecondary))
            else
              ...teams.map((t) {
                final team = t as Map<String, dynamic>;
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.group_rounded, size: 20),
                  title: Text(team['name'] ?? 'Team'),
                );
              }),
          ],
        );
      },
    );
  }

  Color _roleColor(String? role) => switch (role) {
    'owner' => Colors.amber,
    'admin' => Colors.purple,
    'manager' => Colors.teal,
    _ => PriVaultColors.primary,
  };

  void _showAddMemberDialog(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController();
    String role = 'employee';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  DropdownMenuItem(value: 'employee', child: Text('Employee')),
                  DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                ],
                onChanged: (v) => setDialogState(() => role = v!),
                decoration: const InputDecoration(labelText: 'Role'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final api = ref.read(apiClientProvider);
                  await api.post('/companies/$companyId/members', body: {
                    'email': emailCtrl.text.trim(),
                    'role': role,
                  });
                  ref.invalidate(companyDetailProvider(companyId));
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Team'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Team Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final api = ref.read(apiClientProvider);
                await api.post('/companies/$companyId/teams', body: {'name': nameCtrl.text.trim()});
                ref.invalidate(companyDetailProvider(companyId));
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      'owner' => Colors.amber,
      'admin' => Colors.purple,
      'manager' => Colors.teal,
      _ => PriVaultColors.primary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(role.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
