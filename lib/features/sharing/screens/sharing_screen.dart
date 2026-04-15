// ============================================================
// PriVault – Sharing Screen
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/features/sharing/providers/sharing_provider.dart';
import 'package:pri_vault/features/sharing/screens/shared_with_me_screen.dart';
import 'package:pri_vault/models/share_models.dart';

class SharingScreen extends ConsumerStatefulWidget {
  const SharingScreen({super.key});

  @override
  ConsumerState<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends ConsumerState<SharingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PriVaultColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ─────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'Shared Files',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,),
              ),
            ),

            // ── Tab Switcher ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: PriVaultColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _Tab(
                      label: 'Shared by me',
                      active: _tabController.index == 0,
                      onTap: () => _tabController.animateTo(0),
                    ),
                    _Tab(
                      label: 'Shared with me',
                      active: _tabController.index == 1,
                      onTap: () => _tabController.animateTo(1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Content ─────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _ManagedSharesList(),
                  SharedWithMeScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab widget ─────────────────────────────────────────────────
class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: active ? PriVaultColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: active ? Colors.white : PriVaultColors.textHint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared by me list ──────────────────────────────────────────
class _ManagedSharesList extends ConsumerWidget {
  const _ManagedSharesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharesAsync = ref.watch(ownerSharesProvider);

    return sharesAsync.when(
      data: (shares) {
        final active = shares.where((s) => !s.$1.isRevoked).toList();
        final revoked = shares.where((s) => s.$1.isRevoked).toList();
        final all = [...active, ...revoked];

        if (all.isEmpty) return const _EmptyState(isOwner: true);

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
          itemCount: all.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final (share, file) = all[i];
            return _ShareCard(share: share, fileName: file?.name);
          },
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.white),),),
    );
  }
}

// ── Share Card ─────────────────────────────────────────────────
class _ShareCard extends ConsumerWidget {
  final Share share;
  final String? fileName;
  const _ShareCard({required this.share, this.fileName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLink = share.type == 'link';
    final isUser = share.type == 'user';
    final isRevoked = share.isRevoked;
    final isExpired = share.isExpired;
    final isActive = share.isActive;

    // Type color
    final typeColor = isLink
        ? Colors.blueAccent
        : isUser
            ? Colors.tealAccent
            : PriVaultColors.primary;

    // Status color
    final statusColor = isRevoked
        ? PriVaultColors.error
        : isExpired
            ? PriVaultColors.warning
            : PriVaultColors.success;

    final statusLabel = isRevoked
        ? 'Revoked'
        : isExpired
            ? 'Expired'
            : 'Active';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PriVaultColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRevoked
              ? PriVaultColors.error.withValues(alpha: 0.3)
              : PriVaultColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: icon + name + type badge ──────────────
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLink
                      ? Icons.link_rounded
                      : isUser
                          ? Icons.person_rounded
                          : Icons.group_rounded,
                  color: typeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName ?? 'Deleted file',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isRevoked
                            ? PriVaultColors.textHint
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        decoration: isRevoked
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(share.createdAt),
                      style: const TextStyle(
                          color: PriVaultColors.textHint,
                          fontSize: 11,),
                    ),
                  ],
                ),
              ),
              // Type badge
              _Badge(label: share.displayType, color: typeColor),
            ],
          ),
          const SizedBox(height: 12),

          // ── Row 2: recipient + permission ─────────────────
          Row(
            children: [
              if (isLink)
                const _InfoChip(
                    icon: Icons.public_rounded, label: 'Public link',),
              if (isUser && share.sharedWithEmail != null)
                _InfoChip(
                    icon: Icons.email_outlined,
                    label: share.sharedWithEmail!,),
              if (!isLink && !isUser)
                const _InfoChip(
                    icon: Icons.group_rounded, label: 'Team',),
              const SizedBox(width: 8),
              _InfoChip(
                icon: share.permission == 'download'
                    ? Icons.download_outlined
                    : Icons.visibility_outlined,
                label: share.permission == 'download'
                    ? 'Download'
                    : 'View only',
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Row 3: expiry ─────────────────────────────────
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 13, color: PriVaultColors.textHint,),
              const SizedBox(width: 4),
              Text(
                share.expiresAt == null
                    ? 'No expiry'
                    : 'Expires ${_formatDate(share.expiresAt)}',
                style: const TextStyle(
                    color: PriVaultColors.textHint, fontSize: 12,),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Row 4: status + actions ───────────────────────
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),),),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status dot + label
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,),),
                  ],
                ),

                // Actions
                Row(
                  children: [
                    // Copy link button (link type only)
                    if (isLink && isActive)
                      _ActionButton(
                        icon: Icons.copy_rounded,
                        label: 'Copy',
                        color: Colors.blueAccent,
                        onTap: () {
                          final link =
                              'https://privault.app/s/${share.id}';
                          Clipboard.setData(
                              ClipboardData(text: link),);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Link copied'),
                              backgroundColor: PriVaultColors.success,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),

                    if (isActive) ...[
                      if (isLink) const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.block_rounded,
                        label: 'Revoke',
                        color: PriVaultColors.error,
                        onTap: () =>
                            _confirmRevoke(context, ref, share),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRevoke(
      BuildContext context, WidgetRef ref, Share share,) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PriVaultColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Revoke Access?',
            style: TextStyle(color: Colors.white),),
        content: const Text(
          'This will immediately disable access for all recipients. This cannot be undone.',
          style: TextStyle(color: PriVaultColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: PriVaultColors.textHint),),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: PriVaultColors.error,),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(sharingProvider.notifier)
          .revokeShare(share.fileId ?? '', share.id);
      ref.invalidate(ownerSharesProvider);
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Small reusable widgets ─────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600,),),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: PriVaultColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: PriVaultColors.textSecondary, fontSize: 12,),),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,),),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isOwner;
  const _EmptyState({required this.isOwner});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: PriVaultColors.surfaceLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: PriVaultColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: PriVaultColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOwner
                    ? Icons.share_rounded
                    : Icons.people_alt_rounded,
                size: 32,
                color: PriVaultColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isOwner
                  ? 'No files shared yet'
                  : 'No files shared with you',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,),
            ),
            const SizedBox(height: 8),
            Text(
              isOwner
                  ? 'Open a file and tap Share to get started'
                  : 'Files others share with you will appear here',
              style: const TextStyle(
                  color: PriVaultColors.textHint, fontSize: 12,),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}