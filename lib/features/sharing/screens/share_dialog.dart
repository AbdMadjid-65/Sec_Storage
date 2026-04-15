import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/theme/app_theme.dart';


import 'package:pri_vault/features/sharing/providers/sharing_provider.dart';
import 'package:pri_vault/models/file_metadata.dart';


class ShareDialog extends ConsumerStatefulWidget {
  final FileMetadata file;
  final String decryptedName;

  const ShareDialog({
    super.key,
    required this.file,
    required this.decryptedName,
  });

  @override
  ConsumerState<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends ConsumerState<ShareDialog> {
  String? _generatedLink;
  String _permission = 'view'; // BR-14: 'view'|'download'|'edit'
  DateTime? _expiresAt; // BR-13: optional expiry

  final _emailController = TextEditingController();
  final _teamNameController = TextEditingController();
  final _teamMemberController = TextEditingController();
  String? _selectedTeamId;

  Future<void> _createPublicLink() async {
    try {
      final url = await ref
          .read(sharingProvider.notifier)
          .createPublicLink(
            widget.file,
            permission: _permission,
            expiresAt: _expiresAt,
          );
      if (url != null) {
        setState(() => _generatedLink = url);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create link: $e')),
      );
    }
  }

  Future<void> _shareWithUser() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    try {
      await ref.read(sharingProvider.notifier).shareWithUser(
            file: widget.file,
            email: email,
            permission: _permission,
            expiresAt: _expiresAt,
          );

      _emailController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shared securely with $email')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share: $e')),
      );
    }
  }

  Future<void> _createTeam() async {
    final name = _teamNameController.text.trim();
    if (name.isEmpty) return;
    try {
      final teamId = await ref.read(sharingProvider.notifier).createTeam(name);
      setState(() => _selectedTeamId = teamId);
      _teamNameController.clear();
      ref.invalidate(myTeamsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team created')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create team: $e')),
      );
    }
  }

  Future<void> _addMemberToTeam() async {
    final teamId = _selectedTeamId;
    final member = _teamMemberController.text.trim();
    if (teamId == null || member.isEmpty) return;
    try {
      await ref.read(sharingProvider.notifier).addTeamMember(
            teamId: teamId,
            memberIdentifier: member,
          );
      _teamMemberController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member added to team')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add member: $e')),
      );
    }
  }

  Future<void> _shareWithTeam() async {
    final teamId = _selectedTeamId;
    if (teamId == null) return;
    try {
      await ref.read(sharingProvider.notifier).shareWithTeam(
            file: widget.file,
            teamId: teamId,
            permission: _permission,
            expiresAt: _expiresAt,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File shared with team')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share with team: $e')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _teamNameController.dispose();
    _teamMemberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: PriVaultColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PriVaultColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      color: PriVaultColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Share File', style: TextStyle(color: PriVaultColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(
                          widget.decryptedName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const TabBar(
              indicatorColor: PriVaultColors.primary,
              labelColor: PriVaultColors.primary,
              unselectedLabelColor: PriVaultColors.textSecondary,
              dividerColor: PriVaultColors.divider,
              tabs: [
                Tab(text: 'Public Link'),
                Tab(text: 'Add User'),
                Tab(text: 'Team'),
              ],
            ),
            SizedBox(
              height: 380,
              child: TabBarView(
                children: [
                  _buildPublicLinkTab(),
                  _buildAddUserTab(),
                  _buildTeamTab(),
                ],
              ),
            ),
            _buildActiveSharesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicLinkTab() {
    final sharingState = ref.watch(sharingProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PriVaultColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PriVaultColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: PriVaultColors.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Create a zero-knowledge link. The decryption key is embedded in the URL and never sent to our servers.',
                    style: TextStyle(color: PriVaultColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (sharingState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_generatedLink != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: PriVaultColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: PriVaultColors.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PriVaultColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      _generatedLink!,
                      style: const TextStyle(
                        color: PriVaultColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generatedLink!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy Link', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _createPublicLink,
              icon: const Icon(Icons.link_rounded),
              label: const Text('Generate Secure Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          const SizedBox(height: 16),
          // BR-14: Permission chooser
          _buildPermissionDropdown(),
          const SizedBox(height: 12),
          // BR-13: Expiry date picker
          _buildExpiryPicker(),
        ],
      ),
    );
  }

  Widget _buildAddUserTab() {
    final sharingState = ref.watch(sharingProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PriVaultColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PriVaultColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.security_rounded, color: PriVaultColors.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Share directly with another PriVault user. The file key is encrypted with their public key.',
                    style: TextStyle(color: PriVaultColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'User Email',
              prefixIcon: const Icon(Icons.email_rounded),
              filled: true,
              fillColor: PriVaultColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          // BR-14: Permission chooser
          _buildPermissionDropdown(),
          const SizedBox(height: 12),
          // BR-13: Expiry date picker
          _buildExpiryPicker(),
          const SizedBox(height: 24),
          if (sharingState.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _shareWithUser,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Share Internally', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: PriVaultColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _permission,
        decoration: const InputDecoration(
          labelText: 'Permission',
          border: InputBorder.none,
          icon: Icon(Icons.security_rounded, color: PriVaultColors.primary),
        ),
        dropdownColor: PriVaultColors.surface,
        items: const [
          DropdownMenuItem(value: 'view', child: Text('View Only')),
          DropdownMenuItem(value: 'download', child: Text('View & Download')),
          DropdownMenuItem(value: 'edit', child: Text('View, Download, Edit')),
        ],
        onChanged: (v) => setState(() => _permission = v ?? 'view'),
      ),
    );
  }

  Widget _buildTeamTab() {
    final teamsAsync = ref.watch(myTeamsProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _teamNameController,
              decoration: InputDecoration(
                labelText: 'Create Team',
                hintText: 'Team name',
                prefixIcon: const Icon(Icons.group_add_rounded),
                filled: true,
                fillColor: PriVaultColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _createTeam,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Team'),
            ),
            const SizedBox(height: 16),
            teamsAsync.when(
              data: (teams) => DropdownButtonFormField<String>(
                initialValue: _selectedTeamId,
                hint: const Text('Select team'),
                items: teams
                    .map(
                      (t) => DropdownMenuItem<String>(
                        value: t['id'] as String,
                        child: Text(t['name'] as String? ?? 'Unnamed Team'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedTeamId = v),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Teams error: $e'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _teamMemberController,
              decoration: InputDecoration(
                labelText: 'Add Member',
                hintText: 'email / user id',
                prefixIcon: const Icon(Icons.person_add_rounded),
                filled: true,
                fillColor: PriVaultColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addMemberToTeam,
              icon: const Icon(Icons.group_rounded),
              label: const Text('Add Member'),
            ),
            const SizedBox(height: 12),
            _buildPermissionDropdown(),
            const SizedBox(height: 8),
            _buildExpiryPicker(),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _shareWithTeam,
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share File with Team'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryPicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() => _expiresAt = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: PriVaultColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: PriVaultColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _expiresAt != null
                    ? 'Expires: ${_expiresAt!.month}/${_expiresAt!.day}/${_expiresAt!.year}'
                    : 'No Expiry (tap to set)',
                style: TextStyle(
                  color: _expiresAt != null ? Colors.white : PriVaultColors.textSecondary,
                ),
              ),
            ),
            if (_expiresAt != null)
              GestureDetector(
                onTap: () => setState(() => _expiresAt = null),
                child: const Icon(Icons.clear_rounded, color: PriVaultColors.textHint, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSharesList() {
    final sharesAsync = ref.watch(fileSharesProvider(widget.file.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            'Active Shares',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          height: 180,
          child: sharesAsync.when(
            data: (shares) {
              if (shares.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link_off_rounded, size: 40, color: PriVaultColors.textHint.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      const Text(
                        'No active shares',
                        style: TextStyle(color: PriVaultColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: shares.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final share = shares[index];
                  final isLink = share.type == 'link';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: PriVaultColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: PriVaultColors.surfaceLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: PriVaultColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isLink ? Icons.link_rounded : Icons.person_rounded,
                            color: isLink ? Colors.blueAccent : Colors.tealAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isLink ? 'Public Link' : 'Shared with User',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Created: ${share.createdAt?.toIso8601String().split('T').first ?? "Unknown"}',
                                style: const TextStyle(color: PriVaultColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.cancel_rounded,
                            color: Colors.redAccent,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                          ),
                          onPressed: () async {
                            await ref
                                .read(shareRepositoryProvider)
                                .revokeShare(share.id);
                            ref.invalidate(fileSharesProvider(widget.file.id));
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }
}
