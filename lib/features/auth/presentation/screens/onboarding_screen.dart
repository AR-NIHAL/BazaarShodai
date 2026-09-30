import 'package:flutter/material.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../buyer/presentation/screens/main_nav_screen.dart';
import 'login_screen.dart';

/// Model representing each onboarding slide's content and visual assets.
class _OnboardingSlideData {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final String imageUrl;
  final String assetPath;

  const _OnboardingSlideData({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.imageUrl,
    required this.assetPath,
  });
}

/// Modern full-screen immersive Onboarding Screen for BazaarShodai.
/// Uses realistic full-bleed photography, cinematic lighting scrims,
/// and clear dual value propositions for both shoppers and local merchants.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlideData> _slides = const [
    _OnboardingSlideData(
      title: 'Farm-Fresh Groceries at Your Door',
      subtitle:
          'Handpicked chemical-free vegetables, fresh river fish, pure dairy, and daily staples sourced directly from verified local growers.',
      badge: '100% Organic & Fresh',
      icon: Icons.eco_rounded,
      imageUrl: 'https://i.ibb.co/fYv8x8sT/onboarding-1.jpg',
      assetPath: 'assets/images/onboarding_1.jpg',
    ),
    _OnboardingSlideData(
      title: 'Empowering Local Farmers & Sellers',
      subtitle:
          'Launch your digital storefront in minutes. Snap photos of your fresh produce, set fair prices, and reach thousands of neighborhood customers.',
      badge: 'Multi-Vendor Marketplace',
      icon: Icons.storefront_rounded,
      imageUrl: 'https://i.ibb.co/PZnd9VB2/onboarding-2.jpg',
      assetPath: 'assets/images/onboarding_2.jpg',
    ),
    _OnboardingSlideData(
      title: 'Fair Prices & Fast Doorstep Delivery',
      subtitle:
          'Transparent daily market rates, live order tracking, and eco-friendly swift doorstep delivery right to your kitchen.',
      badge: 'Fast & Reliable Delivery',
      icon: Icons.electric_moped_rounded,
      imageUrl: 'https://i.ibb.co/7xywP9Bt/onboarding-3.jpg',
      assetPath: 'assets/images/onboarding_3.jpg',
    ),
  ];

  Future<void> _completeOnboarding() async {
    await LocalStorageService.setOnboardingCompleted(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavScreen()),
    );
  }

  Future<void> _openSellerSignIn() async {
    await LocalStorageService.setOnboardingCompleted(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavScreen()),
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-Screen PageView with full bleed realistic background images
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Full-bleed realistic image covering entire screen
                  _buildFullScreenImage(slide),

                  // Top & bottom cinematic scrim gradient overlays
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.65),
                            Colors.black.withValues(alpha: 0.15),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.60),
                            Colors.black.withValues(alpha: 0.88),
                            Colors.black.withValues(alpha: 0.98),
                          ],
                          stops: const [0.0, 0.14, 0.38, 0.65, 0.84, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Slide content positioned in the lower portion of the screen
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        24,
                        0,
                        24,
                        isLastSlide ? 165 : 125,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Modern Frosted Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  slide.icon,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  slide.badge,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Large Editorial Title
                          Text(
                            slide.title,
                            style: const TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                              letterSpacing: -0.6,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(0, 2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Subtitle with balanced readability
                          Text(
                            slide.subtitle,
                            style: TextStyle(
                              fontSize: 14.5,
                              color: Colors.white.withValues(alpha: 0.90),
                              height: 1.45,
                              shadows: const [
                                Shadow(
                                  color: Colors.black45,
                                  offset: Offset(0, 1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. Floating Top Bar with Brand Badge & Frosted Skip Button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.40),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_basket_rounded,
                            color: Color(0xFF34D399),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'BazaarShodai',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Skip Button
                    if (!isLastSlide)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _completeOnboarding,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.40),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Bottom Controls: Indicators + Actions
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animated Page Indicator
                    Row(
                      children: List.generate(_slides.length, (index) {
                        final isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.only(right: 6),
                          height: 5,
                          width: isActive ? 28 : 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF10B981)
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),

                    // Action Buttons
                    if (isLastSlide) ...[
                      // Primary Action: Start Shopping as Guest
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _completeOnboarding,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Start Shopping as Guest',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Secondary Action: Seller Portal / Sign In
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _openSellerSignIn,
                          icon: const Icon(
                            Icons.storefront_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Are you a seller? Sign In / Join Here',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.12),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _completeOnboarding,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.35),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Explore as Guest',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeInOutCubic,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Next',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.chevron_right_rounded, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the full-screen background image with hybrid loading (CDN + Asset fallback).
  Widget _buildFullScreenImage(_OnboardingSlideData slide) {
    return Image.network(
      slide.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFF131A15),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2.5,
              color: const Color(0xFF10B981),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Fallback to local asset
        return Image.asset(
          slide.assetPath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            // Secondary fallback if asset not yet bundled in web dev cache
            return Container(
              color: const Color(0xFF131A15),
              child: Center(
                child: Icon(
                  slide.icon,
                  size: 72,
                  color: const Color(0xFF10B981),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
