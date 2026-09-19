import 'package:flutter/material.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../buyer/presentation/screens/main_nav_screen.dart';

/// Introductory Onboarding Screen introducing BazaarShodai's multi-vendor grocery marketplace.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Farm-Fresh Groceries',
      'subtitle':
          'Fresh organic vegetables, fruits, and daily kitchen staples sourced directly from verified local growers.',
      'icon': Icons.eco_rounded,
      'badge': '100% Fresh',
    },
    {
      'title': 'Multi-Vendor Marketplace',
      'subtitle':
          'Empowering neighborhood merchants and local sellers. Compare authentic goods and discover the best deals.',
      'icon': Icons.storefront_rounded,
      'badge': 'Local Sellers',
    },
    {
      'title': 'Seamless Direct Delivery',
      'subtitle':
          'Doorstep delivery with transparent updates. Explore our entire catalog freely without forced sign-in.',
      'icon': Icons.delivery_dining_rounded,
      'badge': 'Fast & Reliable',
    },
  ];

  Future<void> _completeOnboarding() async {
    await LocalStorageService.setOnboardingCompleted(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastSlide = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!isLastSlide)
            TextButton(
              onPressed: _completeOnboarding,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // PageView Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon Illustration Container
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              slide['icon'] as IconData,
                              size: 80,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryLight.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            slide['badge'] as String,
                            style: const TextStyle(
                              color: AppColors.secondaryDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subtitle
                        Text(
                          slide['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Navigation & Action Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isActive ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons
                  if (isLastSlide)
                    ElevatedButton(
                      onPressed: _completeOnboarding,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Start Exploring'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _completeOnboarding,
                            child: const Text('Explore as Guest'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Next'),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
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
