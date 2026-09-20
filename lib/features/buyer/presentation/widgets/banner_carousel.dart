import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Promotional banner matching BazaarShodai reference design.
/// Features deep teal river gradient, authentic Bengali product highlights,
/// "Shop Now →" call-to-action button, and circular discount badge.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  final List<Map<String, dynamic>> _banners = [
    {
      'tagline': 'Taste the Pride of Bangladesh',
      'title': 'Padma Hilsa\nSpecial',
      'subtitle': 'Fresh. Authentic. From our rivers to your table.',
      'buttonText': 'Shop Now →',
      'bgGradient': const [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF025949)],
      'buttonColor': const Color(0xFFD97706),
      'icon': Icons.set_meal_rounded,
    },
    {
      'tagline': '100% Organic & Direct from Farm',
      'title': 'Bogura Fresh\nVegetables',
      'subtitle': 'Naturally harvested every morning without preservatives.',
      'buttonText': 'Explore →',
      'bgGradient': const [Color(0xFF0F766E), Color(0xFF115E59), Color(0xFF134E4A)],
      'buttonColor': const Color(0xFFD97706),
      'icon': Icons.eco_rounded,
    },
    {
      'tagline': 'Pure Heritage & Authentic Taste',
      'title': 'Ghani Bhanga\nMustard Oil',
      'subtitle': 'Cold-pressed naturally with pungent traditional aroma.',
      'buttonText': 'Order Now →',
      'bgGradient': const [Color(0xFF78350F), Color(0xFF92400E), Color(0xFFB45309)],
      'buttonColor': const Color(0xFF059669),
      'icon': Icons.water_drop_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % _banners.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: banner['bgGradient'] as List<Color>,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (banner['bgGradient'] as List<Color>).first.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Water ripple / decorative river curves & icon
                      Positioned(
                        right: 16,
                        bottom: 12,
                        child: Icon(
                          banner['icon'] as IconData,
                          size: 110,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),

                      // Content text & responsive CTA button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              banner['tagline'] as String,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              banner['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              banner['subtitle'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Responsive CTA button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(banner['buttonText'] as String),
                                      duration: const Duration(milliseconds: 1500),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: banner['buttonColor'] as Color,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    banner['buttonText'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 5,
              width: isActive ? 18 : 5,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
