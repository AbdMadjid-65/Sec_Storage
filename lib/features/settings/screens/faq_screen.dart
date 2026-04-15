// ============================================================
// PriVault – FAQ (expandable)
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pri_vault/core/theme/app_theme.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _items = <MapEntry<String, String>>[
    MapEntry(
      'What is PriVault?',
      'PriVault is a secure encrypted file storage app. All your files '
          'are encrypted on your device before being uploaded. We never see '
          'your files or encryption keys.',
    ),
    MapEntry(
      'How is my data protected?',
      'PriVault uses XChaCha20-Poly1305 encryption — a military-grade '
          'algorithm. Your master key is derived from your password using '
          'Argon2id. Each file gets its own unique encryption key.',
    ),
    MapEntry(
      'What happens if I forget my password?',
      'Use "Forgot Password" on the login screen. We\'ll send a reset '
          'link to your email. Note: if you lose your encryption key, '
          'encrypted files cannot be recovered.',
    ),
    MapEntry(
      'What are the storage plans?',
      'Free: 3GB | Premium: 20GB (\$19/month) | Professional: Unlimited (\$49/month)',
    ),
    MapEntry(
      'Can I share files with others?',
      'Yes! You can share files via private link (with expiry) or '
          'directly with another user\'s email. Vault files cannot be shared.',
    ),
    MapEntry(
      'What is the Secure Vault?',
      'The Secure Vault is a special encrypted folder requiring '
          'biometric authentication. Files in the vault cannot be shared.',
    ),
    MapEntry(
      'What is the Papers Wallet?',
      'A secure place to store digital copies of your ID, student card, '
          'employee card, and bank cards (masked). Cannot be shared externally.',
    ),
    MapEntry(
      'How does file sharing work?',
      'Files are shared using X25519 key exchange — your encryption key '
          'is re-encrypted for the recipient so they can decrypt the file '
          'without knowing your master key.',
    ),
    MapEntry(
      'How long do deleted files stay in trash?',
      'Deleted files stay in Trash for 30 days then are permanently '
          'removed. You can restore or permanently delete them manually.',
    ),
    MapEntry(
      'Can I upgrade my plan?',
      'Go to Profile → Upgrade Plan. Premium and Professional plans '
          'are coming soon with payment integration.',
    ),
    MapEntry(
      'Is my chat secure?',
      'Chat messages are encrypted before being stored in Firestore. '
          'Only you and your chat partner can read the messages.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PriVaultColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: PriVaultColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: PriVaultColors.cardBorder),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'FAQ',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: PriVaultColors.textPrimary,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final e = _items[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: PriVaultColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: PriVaultColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: PriVaultColors.primary.withValues(alpha: 0.05),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          iconColor: PriVaultColors.primary,
                          collapsedIconColor: PriVaultColors.primary,
                          leading: const Icon(Icons.help_outline_rounded, color: PriVaultColors.primary, size: 22),
                          title: Text(
                            e.key,
                            style: const TextStyle(
                              color: PriVaultColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          children: [
                            Text(
                              e.value,
                              style: const TextStyle(
                                color: PriVaultColors.textSecondary,
                                height: 1.45,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
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
