// ============================================================
// PriVault – Create Share Bottom Sheet
// ============================================================
// 3-step: Type → Configure → Confirm/Copy
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/features/sharing/providers/sharing_provider.dart';
import 'package:pri_vault/models/file_metadata.dart';

enum _ShareType { link, user, team }
enum _ShareStep { pickType, configure, confirm }

class CreateShareSheet extends ConsumerStatefulWidget {
  final FileMetadata file;
  const CreateShareSheet({super.key, required this.file});

  @override
  ConsumerState<CreateShareSheet> createState() => _CreateShareSheetState();
}

class _CreateShareSheetState extends ConsumerState<CreateShareSheet> {
  _ShareStep _step = _ShareStep.pickType;
  _ShareType _type = _ShareType.link;

  // Config
  String _permission = 'view'; // 'view' or 'download'
  DateTime? _expiresAt;        // null = permanent
  final _emailController = TextEditingController();
  final _teamIdController = TextEditingController();

  // Result
  String? _generatedLink;

  @override
  void dispose() {
    _emailController.dispose();
    _teamIdController.dispose();
    super.dispose();
  }

  // ── Step 1 → Step 2 ───────────────────────────────────────
  void _onTypePicked(_ShareType type) {
    setState(() {
      _type = type;
      _step = _ShareStep.configure;
    });
  }

  // ── Step 2 → Step 3: create the share ─────────────────────
  Future<void> _onConfirm() async {
    final notifier = ref.read(sharingProvider.notifier);

    try {
      if (_type == _ShareType.link) {
        final link = await notifier.createPublicLink(
          widget.file,
          permission: _permission,
          expiresAt: _expiresAt,
        );
        setState(() {
          _generatedLink = link;
          _step = _ShareStep.confirm;
        });
      } else if (_type == _ShareType.user) {
        final email = _emailController.text.trim();
        if (email.isEmpty) { _showError('Please enter an email.'); return; }
        await notifier.shareWithUser(
          file: widget.file,
          email: email,
          permission: _permission,
          expiresAt: _expiresAt,
        );
        setState(() => _step = _ShareStep.confirm);
      } else {
        final teamId = _teamIdController.text.trim();
        if (teamId.isEmpty) { _showError('Please enter a team ID.'); return; }
        await notifier.shareWithTeam(
          file: widget.file,
          teamId: teamId,
          permission: _permission,
          expiresAt: _expiresAt,
        );
        setState(() => _step = _ShareStep.confirm);
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: PriVaultColors.error,
      ),
    );
  }

  void _copyLink() {
    if (_generatedLink == null) return;
    Clipboard.setData(ClipboardData(text: _generatedLink!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        backgroundColor: PriVaultColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(sharingProvider).isLoading;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: PriVaultColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: PriVaultColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title + file name
          Text(
            'Share File',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.file.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PriVaultColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),

          // ── Step content ─────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (_step) {
              _ShareStep.pickType => _PickTypeStep(
                  key: const ValueKey('pick'),
                  onPick: _onTypePicked,
                ),
              _ShareStep.configure => _ConfigureStep(
                  key: const ValueKey('config'),
                  type: _type,
                  permission: _permission,
                  expiresAt: _expiresAt,
                  emailController: _emailController,
                  teamIdController: _teamIdController,
                  isLoading: isLoading,
                  onPermissionChanged: (v) =>
                      setState(() => _permission = v),
                  onExpiryChanged: (v) =>
                      setState(() => _expiresAt = v),
                  onBack: () =>
                      setState(() => _step = _ShareStep.pickType),
                  onConfirm: _onConfirm,
                ),
              _ShareStep.confirm => _ConfirmStep(
                  key: const ValueKey('confirm'),
                  type: _type,
                  generatedLink: _generatedLink,
                  recipientEmail: _emailController.text.trim(),
                  onCopy: _copyLink,
                  onDone: () => Navigator.of(context).pop(),
                ),
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STEP 1 — Pick share type
// ─────────────────────────────────────────────────────────────
class _PickTypeStep extends StatelessWidget {
  final void Function(_ShareType) onPick;
  const _PickTypeStep({super.key, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TypeTile(
          icon: Icons.link_rounded,
          color: Colors.blueAccent,
          title: 'Share via Link',
          subtitle: 'Anyone with the link can access based on permissions',
          onTap: () => onPick(_ShareType.link),
        ),
        const SizedBox(height: 12),
        _TypeTile(
          icon: Icons.person_rounded,
          color: Colors.tealAccent,
          title: 'Share with User',
          subtitle: 'Share directly with a specific person by email',
          onTap: () => onPick(_ShareType.user),
        ),
        const SizedBox(height: 12),
        _TypeTile(
          icon: Icons.group_rounded,
          color: PriVaultColors.accent,
          title: 'Share with Team',
          subtitle: 'Share with a group — same permissions for everyone',
          onTap: () => onPick(_ShareType.team),
        ),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TypeTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PriVaultColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PriVaultColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: PriVaultColors.textHint, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: PriVaultColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STEP 2 — Configure
// ─────────────────────────────────────────────────────────────
class _ConfigureStep extends StatelessWidget {
  final _ShareType type;
  final String permission;
  final DateTime? expiresAt;
  final TextEditingController emailController;
  final TextEditingController teamIdController;
  final bool isLoading;
  final void Function(String) onPermissionChanged;
  final void Function(DateTime?) onExpiryChanged;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  const _ConfigureStep({
    super.key,
    required this.type,
    required this.permission,
    required this.expiresAt,
    required this.emailController,
    required this.teamIdController,
    required this.isLoading,
    required this.onPermissionChanged,
    required this.onExpiryChanged,
    required this.onBack,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Recipient field (user or team) ──────────────────
        if (type == _ShareType.user) ...[
          const Text('Recipient Email',
              style: TextStyle(
                  color: PriVaultColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'user@example.com',
              hintStyle:
                  const TextStyle(color: PriVaultColors.textHint),
              prefixIcon: const Icon(Icons.email_outlined,
                  color: PriVaultColors.textHint, size: 20),
              filled: true,
              fillColor: PriVaultColors.surfaceLight,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: PriVaultColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (type == _ShareType.team) ...[
          const Text('Team ID',
              style: TextStyle(
                  color: PriVaultColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: teamIdController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter team ID',
              hintStyle:
                  const TextStyle(color: PriVaultColors.textHint),
              prefixIcon: const Icon(Icons.group_rounded,
                  color: PriVaultColors.textHint, size: 20),
              filled: true,
              fillColor: PriVaultColors.surfaceLight,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: PriVaultColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Permission toggle ───────────────────────────────
        const Text('Permission',
            style: TextStyle(
                color: PriVaultColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: PriVaultColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _PermOption(
                label: 'View Only',
                icon: Icons.visibility_outlined,
                selected: permission == 'view',
                onTap: () => onPermissionChanged('view'),
              ),
              _PermOption(
                label: 'Download',
                icon: Icons.download_outlined,
                selected: permission == 'download',
                onTap: () => onPermissionChanged('download'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Expiry ──────────────────────────────────────────
        const Text('Link Expiry',
            style: TextStyle(
                color: PriVaultColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        _ExpiryPicker(
          selected: expiresAt,
          onChanged: onExpiryChanged,
        ),
        const SizedBox(height: 24),

        // ── Buttons ─────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : onBack,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: PriVaultColors.divider),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Back',
                    style: TextStyle(color: PriVaultColors.textHint)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _GradientButton(
                onPressed: isLoading ? null : onConfirm,
                isLoading: isLoading,
                label: type == _ShareType.link
                    ? 'Generate Link'
                    : 'Share Now',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PermOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PermOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? PriVaultColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected
                      ? Colors.white
                      : PriVaultColors.textHint),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? Colors.white
                          : PriVaultColors.textHint)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpiryPicker extends StatelessWidget {
  final DateTime? selected;
  final void Function(DateTime?) onChanged;

  const _ExpiryPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = <(String, DateTime?)>[
      ('No expiry', null),
      ('1 day', DateTime.now().add(const Duration(days: 1))),
      ('7 days', DateTime.now().add(const Duration(days: 7))),
      ('30 days', DateTime.now().add(const Duration(days: 30))),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt.$2?.day == selected?.day &&
            opt.$2?.month == selected?.month &&
            opt.$2?.year == selected?.year ||
            (opt.$2 == null && selected == null);

        return GestureDetector(
          onTap: () => onChanged(opt.$2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? PriVaultColors.primary.withValues(alpha: 0.15)
                  : PriVaultColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? PriVaultColors.primary
                    : PriVaultColors.cardBorder,
              ),
            ),
            child: Text(
              opt.$1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? PriVaultColors.primary
                    : PriVaultColors.textHint,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STEP 3 — Confirm / Copy
// ─────────────────────────────────────────────────────────────
class _ConfirmStep extends StatelessWidget {
  final _ShareType type;
  final String? generatedLink;
  final String recipientEmail;
  final VoidCallback onCopy;
  final VoidCallback onDone;

  const _ConfirmStep({
    super.key,
    required this.type,
    required this.generatedLink,
    required this.recipientEmail,
    required this.onCopy,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success icon
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: PriVaultColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: PriVaultColors.success, size: 36),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          type == _ShareType.link
              ? 'Link Created!'
              : type == _ShareType.user
                  ? 'Shared Successfully!'
                  : 'Shared with Team!',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          type == _ShareType.link
              ? 'Copy the link below and send it to anyone'
              : type == _ShareType.user
                  ? 'File shared with $recipientEmail'
                  : 'Team members can now access this file',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: PriVaultColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),

        // Show link if it's a link share
        if (generatedLink != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: PriVaultColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PriVaultColors.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    generatedLink!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: PriVaultColors.primary,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded,
                      color: PriVaultColors.primary, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _GradientButton(label: 'Copy Link', onPressed: onCopy),
          const SizedBox(height: 10),
        ],

        TextButton(
          onPressed: onDone,
          child: const Text('Done',
              style: TextStyle(
                  color: PriVaultColors.textHint, fontSize: 14)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Gradient Button helper
// ─────────────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GradientButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? null
              : PriVaultColors.primaryGradient,
          color: onPressed == null ? PriVaultColors.divider : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
        ),
      ),
    );
  }
}