import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/buyer_providers.dart';

/// Promotional hero banner carousel for BazaarShodai buyers.
/// Features:
/// - High-resolution authentic local photography (Padma Hilsa, Fresh Bogura Vegetables, Pure Mustard Oil)
/// - Hybrid network + local asset loading so images load instantly on Flutter Web without dev server 404s
/// - Directional gradient scrim ensuring high typography legibility while keeping products vibrant
/// - Zero-overflow adaptive layout with FittedBox protection for all screen sizes and font scales
/// - Interactive CTA buttons and card taps that directly filter the marketplace catalog
/// - Smooth auto-slide transitions with indicator pills
class BannerCarousel extends ConsumerStatefulWidget {
  const BannerCarousel({super.key});

  @override
  ConsumerState<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<BannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  final List<Map<String, dynamic>> _banners = [
    {
      'tagline': 'Taste the Pride of Bangladesh',
      'title': 'Padma Hilsa\nSpecial',
      'subtitle': 'Fresh. Authentic. From our rivers to your table.',
      'buttonText': 'Shop Hilsa →',
      'networkImage': 'https://i.ibb.co/Qj9RNXX4/banner-padma-hilsa.jpg',
      'assetImage': 'assets/images/banner_padma_hilsa.jpg',
      'category': 'Fish & Meat',
      'buttonColor': const Color(0xFF047857),
    },
    {
      'tagline': '100% Organic & Direct from Farm',
      'title': 'Bogura Fresh\nVegetables',
      'subtitle': 'Naturally harvested every morning without preservatives.',
      'buttonText': 'Explore Greens →',
      'networkImage': 'https://i.ibb.co/KprQ1QVM/banner-vegetables.jpg',
      'assetImage': 'assets/images/banner_vegetables.jpg',
      'category': 'Vegetables',
      'buttonColor': const Color(0xFF047857),
    },
    {
      'tagline': 'Pure Heritage & Authentic Taste',
      'title': 'Ghani Bhanga\nMustard Oil',
      'subtitle': 'Cold-pressed naturally with pungent traditional aroma.',
      'buttonText': 'Order Oil →',
      'networkImage': 'https://i.ibb.co/tppFMjN4/banner-mustard-oil.jpg',
      'assetImage': 'assets/images/banner_mustard_oil.jpg',
      'category': 'Spices & Oil',
      'buttonColor': const Color(0xFFD97706),
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % _banners.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _handleBannerTap(Map<String, dynamic> banner) {
    final categoryName = banner['category'] as String?;
    if (categoryName != null) {
      ref.read(selectedCategoryProvider.notifier).selectCategory(categoryName);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Filtered marketplace for "$categoryName"'),
          duration: const Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildBannerImage(String networkUrl, String assetPath) {
    return Image.network(
      networkUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) {
        return Image.asset(
          assetPath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => Container(
            color: const Color(0xFF064E3B),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 185,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];
              final networkUrl = banner['networkImage'] as String;
              final assetPath = banner['assetImage'] as String;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleBannerTap(banner),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 1. High-resolution Photography (Hybrid network + asset fallback)
                          _buildBannerImage(networkUrl, assetPath),

                          // 2. Directional Gradient Scrim (Text contrast on left, vibrant photo on right)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.72),
                                    Colors.black.withValues(alpha: 0.35),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.58, 1.0],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),

                          // 3. Content Text & CTA Button (FittedBox prevents any overflow)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 240),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Tagline Pill Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.35),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.25),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          banner['tagline'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),

                                      // Title
                                      Text(
                                        banner['title'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 19.5,
                                          fontWeight: FontWeight.w900,
                                          height: 1.12,
                                          letterSpacing: -0.3,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 6,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // Subtitle
                                      Text(
                                        banner['subtitle'] as String,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.90),
                                          fontSize: 11,
                                          height: 1.25,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black45,
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Responsive CTA Button
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: banner['buttonColor'] as Color,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (banner['buttonColor'] as Color).withValues(alpha: 0.4),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              banner['buttonText'] as String,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 11.5,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 4. Indicator Dots / Micro-Pills inside Banner Card (Bottom-Right)
                          Positioned(
                            bottom: 12,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(_banners.length, (dotIndex) {
                                  final isActive = dotIndex == _currentPage;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                    height: 4,
                                    width: isActive ? 14 : 4,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
