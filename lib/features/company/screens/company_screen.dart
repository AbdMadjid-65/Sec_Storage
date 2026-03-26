// ============================================================
// PriVault – Company Management Screen (BR-18–20, BR-COMP-*)
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/ui/widgets/privault_button.dart';

// --- Providers ---

final userCompaniesProvider = FutureProvider<List<dynamic>>((ref) async {
  final firestore = ref.read(firestoreProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return [];

  // Query companies where the user is a member
  final memberships = await firestore
      .collectionGroup('members')
      .where('userId', isEqualTo: uid)
      .get();

  final companies = <Map<String, dynamic>>[];
  for (final memberDoc in memberships.docs) {
    // members doc path: companies/{companyId}/members/{memberId}
    final companyRef = memberDoc.reference.parent.parent;
    if (companyRef != null) {
      final companyDoc = await companyRef.get();
      if (companyDoc.exists) {
        final data = companyDoc.data() ?? {};
        data['id'] = companyDoc.id;
        data['role'] = memberDoc.data()['role'] ?? 'member';
        companies.add(data);
      }
    }
  }
  return companies;
});

final companyDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, companyId) async {
  final firestore = ref.read(firestoreProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid;

  final companyDoc = await firestore.collection('companies').doc(companyId).get();
  final company = companyDoc.data() ?? {};
  company['id'] = companyDoc.id;

  // Get members
  final membersSnap = await firestore
      .collection('companies')
      .doc(companyId)
      .collection('members')
      .get();
  final members = membersSnap.docs.map((doc) {
    final data = doc.data();
    data['id'] = doc.id;
    return data;
  }).toList();

  // Get teams
  final teamsSnap = await firestore
      .collection('companies')
      .doc(companyId)
      .collection('teams')
      .get();
  final teams = teamsSnap.docs.map((doc) {
    final data = doc.data();
    data['id'] = doc.id;
    return data;
  }).toList();

  // Get current user's role
  String currentRole = 'viewer';
  for (final m in members) {
    if (m['userId'] == uid) {
      currentRole = m['role'] ?? 'viewer';
      break;
    }
  }

  return {
    'company': company,
    'members': members,
    'teams': teams,
    'current_role': currentRole,
  };
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
                     child: Text(
                       'Company Account',
                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
                             fontWeight: FontWeight.w700,
                             color: Colors.white,
                           ),
                     ),
                   ),
                   if (_selectedCompanyId == null)
                     GestureDetector(
                       onTap: _showCreateDialog,
                       child: Container(
                         width: 40,
                         height: 40,
                         decoration: BoxDecoration(
                           color: PriVaultColors.primary.withValues(alpha: 0.1),
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: PriVaultColors.primary.withValues(alpha: 0.2)),
                         ),
                         child: const Icon(Icons.add_business_rounded, color: PriVaultColors.primary, size: 20),
                       ),
                     ),
                ],
              ),
            ),

            Expanded(
              child: companiesAsync.when(
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
            ),
          ],
        ),
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
                final firestore = ref.read(firestoreProvider);
                final uid = FirebaseAuth.instance.currentUser?.uid;
                final userEmail = FirebaseAuth.instance.currentUser?.email;
                if (uid == null) return;

                // Create company doc
                final companyRef = await firestore.collection('companies').add({
                  'name': nameCtrl.text.trim(),
                  'official_email': emailCtrl.text.trim(),
                  'owner_id': uid,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                // Add current user as owner member
                await companyRef.collection('members').doc(uid).set({
                  'userId': uid,
                  'email': userEmail,
                  'role': 'owner',
                  'joinedAt': FieldValue.serverTimestamp(),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: PriVaultColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.business_rounded, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text('Create Your Company', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text(
              'Collaborate with your team and manage files together',
              style: TextStyle(color: PriVaultColors.textHint, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PriVaultButton(
              text: 'Create Company',
              onPressed: onCreate,
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: companies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final c = companies[i] as Map<String, dynamic>;
        return GestureDetector(
          onTap: () => onSelect(c['id'].toString()),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: PriVaultColors.surfaceLight,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: PriVaultColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: PriVaultColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.domain_rounded, color: PriVaultColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['name'] ?? 'Company', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Role: ${c['role'] ?? 'Member'}', style: const TextStyle(color: PriVaultColors.textHint, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: PriVaultColors.textHint, size: 24),
              ],
            ),
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

  static const _teamGradients = <LinearGradient>[
    LinearGradient(colors: [Colors.blueAccent, Colors.cyanAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Colors.purpleAccent, Colors.pinkAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Colors.orangeAccent, Colors.redAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Colors.greenAccent, Colors.tealAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
  ];

  static const _rolesData = [
    {'name': 'Owner', 'icon': Icons.stars_rounded, 'color': Colors.amber},
    {'name': 'Admin', 'icon': Icons.security_rounded, 'color': Colors.redAccent},
    {'name': 'Manager', 'icon': Icons.groups_rounded, 'color': Colors.purpleAccent},
    {'name': 'Employee', 'icon': Icons.domain_rounded, 'color': Colors.blueAccent},
    {'name': 'Viewer', 'icon': Icons.visibility_rounded, 'color': Colors.grey},
  ];

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

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back button line
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onBack,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_rounded, size: 16, color: PriVaultColors.textHint),
                      SizedBox(width: 4),
                      Text('All Companies', style: TextStyle(color: PriVaultColors.textHint, fontWeight: FontWeight.w500, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Company Info Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigoAccent.withValues(alpha: 0.1), Colors.cyanAccent.withValues(alpha: 0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: PriVaultColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.domain_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(company['name'] ?? 'Company', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('${members.length} members • ${teams.length} teams', style: const TextStyle(color: PriVaultColors.textHint, fontSize: 13)),
                          if (company['official_email'] != null && company['official_email'].isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(company['official_email'], style: const TextStyle(color: PriVaultColors.textHint, fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Teams Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Teams', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
                  if (['owner', 'admin', 'manager'].contains(role))
                    GestureDetector(
                      onTap: () => _showCreateTeamDialog(context, ref),
                      child: const Text('Add Team', style: TextStyle(color: Colors.indigoAccent, fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: teams.isEmpty && !['owner', 'admin', 'manager'].contains(role) ? 0 : teams.length + (['owner', 'admin', 'manager'].contains(role) ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == teams.length) {
                    // Add Team Button Box
                    return GestureDetector(
                      onTap: () => _showCreateTeamDialog(context, ref),
                      child: Container(
                        decoration: BoxDecoration(
                          color: PriVaultColors.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1), style: BorderStyle.solid), // Figma uses dashed but solid is easier native
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, color: PriVaultColors.textHint, size: 32),
                            SizedBox(height: 8),
                            Text('Add Team', style: TextStyle(color: PriVaultColors.textHint, fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  }
                  final team = teams[i] as Map<String, dynamic>;
                  final gradient = _teamGradients[i % _teamGradients.length];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: PriVaultColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: PriVaultColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.groups_rounded, color: Colors.white, size: 24),
                        ),
                        const Spacer(),
                        Text(team['name'] ?? 'Team', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.white)),
                        const SizedBox(height: 2),
                        const Text('0 members', style: TextStyle(color: PriVaultColors.textHint, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Roles Legend
              const Text('Roles', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
              const SizedBox(height: 16),
              GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3.5,
                ),
                itemCount: _rolesData.length,
                itemBuilder: (context, index) {
                  final r = _rolesData[index];
                  final cn = r['name'] as String;
                  final icon = r['icon'] as IconData;
                  final color = r['color'] as Color;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: PriVaultColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: PriVaultColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: color, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Text(cn, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.white)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Members
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Members', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
                  if (['owner', 'admin'].contains(role))
                    GestureDetector(
                      onTap: () => _showAddMemberDialog(context, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.indigoAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('Invite', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final member = members[i] as Map<String, dynamic>;
                  final roleStr = member['role'] ?? 'viewer';
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: PriVaultColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: PriVaultColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _roleColor(roleStr).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text((member['email'] ?? '?')[0].toUpperCase(), style: TextStyle(color: _roleColor(roleStr), fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member['display_name'] ?? member['email']?.split('@')[0] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(member['email'] ?? '', style: const TextStyle(color: PriVaultColors.textHint, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.indigoAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.2)),
                          ),
                          child: Text(_capitalize(roleStr), style: const TextStyle(color: Colors.indigoAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }

  Color _roleColor(String? role) => switch (role) {
    'owner' => Colors.amber,
    'admin' => Colors.redAccent,
    'manager' => Colors.purpleAccent,
    'employee' => Colors.blueAccent,
    _ => Colors.grey,
  };

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

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
                  final firestore = ref.read(firestoreProvider);
                  final memberEmail = emailCtrl.text.trim();

                  await firestore
                      .collection('companies')
                      .doc(companyId)
                      .collection('members')
                      .add({
                    'email': memberEmail,
                    'role': role,
                    'joinedAt': FieldValue.serverTimestamp(),
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
                final firestore = ref.read(firestoreProvider);
                await firestore
                    .collection('companies')
                    .doc(companyId)
                    .collection('teams')
                    .add({
                  'name': nameCtrl.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
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

