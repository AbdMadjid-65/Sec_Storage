import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pri_vault/core/router/app_router.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/ui/widgets/privault_button.dart';

class PlanSelectionScreen extends StatefulWidget {
  const PlanSelectionScreen({super.key});

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  String _selectedPlan = 'premium';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'free',
      'name': 'FREE',
      'storage': '3GB',
      'price': '\$0',
      'period': null,
      'badge': 'Current Plan',
      'badgeColor': const Color(0xFF4B5563), // gray-600
      'features': ['3GB Storage', 'Basic encryption', 'Email support'],
      'isComingSoon': false,
    },
    {
      'id': 'premium',
      'name': 'PREMIUM',
      'storage': '20GB',
      'price': '\$19',
      'period': '/month',
      'badge': 'Most Popular',
      'badgeColor': PriVaultColors.primary, // representing the gradient
      'features': [
        '20GB Storage',
        'Advanced encryption',
        'Priority support',
        'Share with expiry',
        'Secure vault',
      ],
      'isComingSoon': false,
    },
    {
      'id': 'professional',
      'name': 'PROFESSIONAL',
      'storage': 'Unlimited',
      'price': '\$49',
      'period': '/month',
      'badge': 'Coming Soon',
      'badgeColor': const Color(0xFF9333EA), // purple-600
      'features': [
        'Unlimited Storage',
        'Team collaboration',
        'Company account',
        '24/7 support',
        'Advanced analytics',
      ],
      'isComingSoon': true,
    },
  ];

  Future<void> _handleContinue() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'plan': _selectedPlan,
        }, SetOptions(merge: true),);
      }
      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: PriVaultColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PriVaultColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Column(
                  children: [
                    // Header
                    const Icon(Icons.auto_awesome_rounded, color: Colors.yellowAccent, size: 28),
                    const SizedBox(height: 16),
                    const Text(
                      'Choose Your Plan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select the perfect plan for your needs',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: PriVaultColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Plans List
                    ..._plans.map((plan) {
                      final isSelected = _selectedPlan == plan['id'] && !plan['isComingSoon'];
                      final isComingSoon = plan['isComingSoon'];

                      return GestureDetector(
                        onTap: () {
                          if (!isComingSoon) {
                            setState(() => _selectedPlan = plan['id']);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Plan coming soon!'), backgroundColor: PriVaultColors.info),
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isSelected ? PriVaultColors.primary.withValues(alpha: 0.1) : PriVaultColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected ? PriVaultColors.primary : PriVaultColors.divider,
                              width: 2,
                            ),
                          ),
                          foregroundDecoration: isComingSoon
                              ? BoxDecoration(
                                  color: PriVaultColors.background.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(24),
                                )
                              : null,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            plan['name'],
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            plan['storage'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: PriVaultColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.baseline,
                                            textBaseline: TextBaseline.alphabetic,
                                            children: [
                                              Text(
                                                plan['price'],
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              if (plan['period'] != null) ...[
                                                const SizedBox(width: 4),
                                                Text(
                                                  plan['period'],
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: PriVaultColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  ...List<Widget>.from(
                                    plan['features'].map(
                                      (feature) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: PriVaultColors.primary.withValues(alpha: 0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.check_rounded, size: 12, color: PriVaultColors.primary),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                feature,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFFD1D5DB), // gray-300
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Badge
                              if (plan['badge'] != null)
                                Positioned(
                                  top: -36,
                                  left: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: plan['badgeColor'],
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: plan['badgeColor'] == PriVaultColors.primary 
                                          ? PriVaultColors.primaryGradient 
                                          : null,
                                    ),
                                    child: Text(
                                      plan['badge'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                              // Selected Checkmark
                              if (isSelected)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      gradient: PriVaultColors.primaryGradient,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: PriVaultButton(
                onPressed: _isLoading ? null : _handleContinue,
                text: 'Continue',
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
