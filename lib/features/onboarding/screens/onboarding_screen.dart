import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:pri_vault/core/router/app_router.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/ui/widgets/privault_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Your files, secured',
      subtitle: 'Store your files with military-grade encryption. Your data is safe and private.',
      icon: Icons.shield_outlined,
      gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    _OnboardingPageData(
      title: 'Share securely',
      subtitle: 'Share files privately with expiry links. Control who sees your files and for how long.',
      icon: Icons.share_outlined,
      gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    _OnboardingPageData(
      title: 'Your digital vault',
      subtitle: 'Keep your most sensitive documents locked in a secure vault with advanced encryption.',
      icon: Icons.lock_outline,
      gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFFEC4899)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    _OnboardingPageData(
      title: 'Your papers wallet',
      subtitle: 'Store IDs, cards, and important documents digitally. Access them anytime, anywhere.',
      icon: Icons.account_balance_wallet_outlined,
      gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final box = Hive.box('settings');
    await box.put('hasSeenOnboarding', true);
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PriVaultColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Icon Container
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            gradient: page.gradient,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: page.gradient.colors.first.withValues(alpha: 0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              page.icon,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        // Text
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: PriVaultColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Bottom Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 32 : 8,
                        decoration: BoxDecoration(
                          gradient: _currentPage == index ? PriVaultColors.primaryGradient : null,
                          color: _currentPage == index ? null : const Color(0xFF374151), // Gray-700
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Buttons
                  PriVaultButton(
                    onPressed: _onNext,
                    text: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                  ),
                  const SizedBox(height: 12),
                  PriVaultButton(
                    onPressed: _finishOnboarding,
                    text: 'Skip',
                    isSecondary: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;

  _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });
}
