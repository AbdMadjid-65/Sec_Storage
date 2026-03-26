import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pri_vault/core/theme/app_theme.dart';

class PlanSelectionSheet extends StatefulWidget {
  final bool isDismissible;
  
  const PlanSelectionSheet({super.key, this.isDismissible = true});

  @override
  State<PlanSelectionSheet> createState() => _PlanSelectionSheetState();
}

class _PlanSelectionSheetState extends State<PlanSelectionSheet> {
  bool _isLoading = false;

  Future<void> _selectFreePlan() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'plan': 'free',
        });
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: PriVaultColors.error),
      );
    }
  }

  void _onComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan coming soon!'), backgroundColor: PriVaultColors.info),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.isDismissible,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: PriVaultColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: PriVaultColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              'Choose your plan',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a plan that fits your cloud storage needs.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PriVaultColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            Expanded(
              child: ListView(
                children: [
                  _PlanCard(
                    title: 'FREE',
                    price: '\$0',
                    billing: 'Forever',
                    features: const ['3GB encrypted storage', 'Basic sharing features', 'Standard vault features'],
                    badgeText: 'Current Plan',
                    badgeColor:PriVaultColors.textSecondary,
                    buttonText: 'Select Free Plan',
                    buttonColor: PriVaultColors.surfaceLight,
                    onTap: _isLoading ? null : _selectFreePlan,
                  ),
                  const SizedBox(height: 16),
                  
                  _PlanCard(
                    title: 'PREMIUM',
                    price: '\$19',
                    billing: '/month',
                    features: const ['20GB encrypted storage', 'Advanced sharing permissions', 'Priority sync'],
                    badgeText: 'Most Popular',
                    badgeColor: PriVaultColors.primary,
                    buttonText: 'Coming Soon',
                    buttonColor: PriVaultColors.primary,
                    onTap: _onComingSoon,
                  ),
                  const SizedBox(height: 16),
                  
                  _PlanCard(
                    title: 'PROFESSIONAL',
                    price: '\$49',
                    billing: '/month',
                    features: const ['Unlimited encrypted storage', 'Enterprise-grade features', '24/7 Priority support'],
                    badgeText: null,
                    badgeColor: Colors.transparent,
                    buttonText: 'Coming Soon',
                    buttonColor: PriVaultColors.surfaceLight,
                    onTap: _onComingSoon,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String billing;
  final List<String> features;
  final String? badgeText;
  final Color badgeColor;
  final String buttonText;
  final Color buttonColor;
  final VoidCallback? onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.billing,
    required this.features,
    this.badgeText,
    required this.badgeColor,
    required this.buttonText,
    required this.buttonColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PriVaultColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: badgeText == 'Most Popular' ? PriVaultColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: PriVaultColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText!,
                    style: TextStyle(
                      color: badgeColor == PriVaultColors.textSecondary ? Colors.white : badgeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  billing,
                  style: const TextStyle(
                    color: PriVaultColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: PriVaultColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    f,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: badgeText == 'Most Popular' ? PriVaultColors.primary : PriVaultColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                buttonText,
                style: TextStyle(
                  color: badgeText == 'Most Popular' ? Colors.white : PriVaultColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
