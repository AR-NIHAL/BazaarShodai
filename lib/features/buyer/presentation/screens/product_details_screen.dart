import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../domain/models/product_model.dart';
import '../widgets/auth_prompt_sheet.dart';

/// Comprehensive Product Details & Description screen matching the BazaarShodai reference Figma design.
class ProductDetailsScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  final PageController _mediaPageController = PageController();
  int _currentMediaIndex = 0;
  bool _isWishlisted = false;
  int _quantity = 1;

  late ProductWeightOption _selectedWeightOption;
  String _selectedCut = '';

  @override
  void initState() {
    super.initState();
    final weightOptions = widget.product.effectiveWeightOptions;
    _selectedWeightOption = weightOptions.isNotEmpty
        ? weightOptions.first
        : ProductWeightOption(label: widget.product.unit, price: widget.product.price);

    final cutOptions = widget.product.effectiveCutOptions;
    _selectedCut = cutOptions.isNotEmpty ? cutOptions.first : '';
  }

  @override
  void dispose() {
    _mediaPageController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      final intPart = price.toInt();
      final thousands = intPart ~/ 1000;
      final remainder = intPart % 1000;
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return price.toStringAsFixed(0);
  }

  void _handleWishlistToggle() {
    final authUser = ref.read(authStateChangesProvider).value;
    if (authUser == null) {
      AuthPromptSheet.show(
        context,
        title: 'Sign In to Save Wishlist',
        message: 'Create a free account to save ${widget.product.title} to your personal wishlist.',
      );
      return;
    }

    setState(() => _isWishlisted = !_isWishlisted);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isWishlisted ? 'Added to wishlist!' : 'Removed from wishlist.'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  void _handleAddToCart() {
    final (success, msg) = ref.read(cartProvider.notifier).addItem(
          widget.product,
          quantity: _quantity,
          unitPrice: _selectedWeightOption.price,
          selectedOption: _selectedWeightOption.label,
          selectedCut: _selectedCut.isNotEmpty ? _selectedCut : null,
        );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? const Color(0xFF047857) : AppColors.warning,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showVideoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.play_circle_fill_rounded, color: Color(0xFF047857), size: 26),
            SizedBox(width: 8),
            Text('Product Freshness Video', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildMediaItem(widget.product.primaryImage),
                  ),
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.product.videoUrl != null && widget.product.videoUrl!.isNotEmpty
                  ? 'Video Source: ${widget.product.videoUrl}'
                  : 'Live harvest & packing clip recorded by ${widget.product.sellerName}.',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaItem(String url) {
    if (url.startsWith('assets/')) {
      return Image.asset(url, fit: BoxFit.cover, width: double.infinity);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, _, _) => Image.asset(
        'assets/images/tomato_sample.jpg',
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) => Container(
          color: const Color(0xFF064E3B),
          child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 48),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryLower = product.category.toLowerCase();
    final isFishOrMeat = categoryLower.contains('fish') || categoryLower.contains('meat');
    final isVegOrFruit = categoryLower.contains('veg') || categoryLower.contains('fruit');

    final List<String> mediaList = product.imageUrls.isNotEmpty
        ? product.imageUrls
        : ['assets/images/tomato_sample.jpg'];

    final activePrice = _selectedWeightOption.price;
    final originalPrice = product.originalPrice ?? (activePrice * 1.2).roundToDouble();
    final savings = originalPrice > activePrice ? originalPrice - activePrice : 0.0;
    final totalPrice = activePrice * _quantity;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFBFDFA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFishOrMeat ? 'DAILY RIVER HARVEST' : 'FARM FRESH HARVEST',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF047857),
                letterSpacing: 0.6,
              ),
            ),
            Text(
              product.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isWishlisted ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              color: _isWishlisted ? const Color(0xFFDC2626) : (isDark ? Colors.white : const Color(0xFF475569)),
            ),
            onPressed: _handleWishlistToggle,
          ),
          IconButton(
            icon: Icon(
              Icons.share_outlined,
              color: isDark ? Colors.white : const Color(0xFF475569),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Share link generated for ${product.title}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Main Media Carousel
                    Stack(
                      children: [
                        SizedBox(
                          height: 250,
                          child: PageView.builder(
                            controller: _mediaPageController,
                            itemCount: mediaList.length,
                            onPageChanged: (i) => setState(() => _currentMediaIndex = i),
                            itemBuilder: (context, index) {
                              return _buildMediaItem(mediaList[index]);
                            },
                          ),
                        ),

                        // Gradient Scrim
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.35),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.45),
                                  ],
                                  stops: const [0.0, 0.4, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Badges: Catch of the Day & Formalin-Free
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF047857),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isFishOrMeat ? Icons.set_meal : Icons.eco,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isFishOrMeat ? 'Catch of the Day (দিনের সেরা ক্যাচ)' : 'Farm Harvest (দিনের তাজা ফসল)',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_user_rounded, size: 12, color: Color(0xFF047857)),
                                    SizedBox(width: 4),
                                    Text(
                                      '100% Formalin-Free Lab Tested',
                                      style: TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Top-Right: Discount Pill Badge
                        if (product.hasDiscount)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                '-${product.discountPercentage}% OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),

                        // Bottom-Right: Slide Count (1/N)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentMediaIndex + 1}/${mediaList.length + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 2. Thumbnails Selector + Video Button + Freshness Tags
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: mediaList.length + 1,
                                separatorBuilder: (_, _) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  if (index == mediaList.length) {
                                    return InkWell(
                                      onTap: _showVideoDialog,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 58,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEEF2FF),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFC7D2FE)),
                                        ),
                                        child: const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.play_circle_fill_rounded, color: Color(0xFF4F46E5), size: 22),
                                            SizedBox(height: 2),
                                            Text(
                                              'Video',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF4F46E5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  final isSelected = index == _currentMediaIndex;
                                  return InkWell(
                                    onTap: () {
                                      _mediaPageController.animateToPage(
                                        index,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 58,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFF047857) : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: _buildMediaItem(mediaList[index]),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF059669)),
                                  const SizedBox(width: 3),
                                  Text(
                                    product.harvestTime ?? 'Harvested 4h ago',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              const Row(
                                children: [
                                  Icon(Icons.ac_unit_rounded, size: 12, color: Color(0xFF0284C7)),
                                  SizedBox(width: 3),
                                  Text(
                                    'Cold-chain kept 0°C',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 3. Express Cold Delivery Banner
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.bolt_rounded, color: Color(0xFFB45309), size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Express Cold Delivery Available',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                  SizedBox(height: 1),
                                  Text(
                                    'Today within 2 hrs to Dhanmondi, Dhaka',
                                    style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD97706),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '2 hr',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 4. Titles, Pricing, Rating & Live Scarcity
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.effectiveOrigin,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            product.title,
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.4,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.effectiveBengaliTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '৳ ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                _formatPrice(activePrice),
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '৳ ${_formatPrice(originalPrice)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF94A3B8),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              if (savings > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEA),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Save ৳ ${_formatPrice(savings)}',
                                    style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 17, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 3),
                              Text(
                                '${product.rating > 0 ? product.rating.toStringAsFixed(1) : "4.9"} (${product.reviewCount > 0 ? product.reviewCount : "134"} reviews)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('·', style: TextStyle(color: Color(0xFF94A3B8))),
                              const SizedBox(width: 8),
                              const Text(
                                '98% Recommended',
                                style: TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              const Text(
                                'See all >',
                                style: TextStyle(fontSize: 12, color: Color(0xFF047857), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDC2626),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                                      children: [
                                        TextSpan(
                                          text: 'Only ${product.stock} items remaining ',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                        ),
                                        TextSpan(
                                          text: isFishOrMeat
                                              ? 'from this morning\'s boat catch. Direct from river landing.'
                                              : 'from today\'s fresh farm harvest.',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 5. Select Weight / Size
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  isFishOrMeat
                                      ? 'Select Weight Size'
                                      : (isVegOrFruit ? 'Select Package Weight' : 'Select Unit / Size'),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isFishOrMeat ? 'Approx. weight per piece' : 'Fresh Pack Options',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                for (final opt in product.effectiveWeightOptions)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: InkWell(
                                      onTap: () => setState(() => _selectedWeightOption = opt),
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        width: 110,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: opt.label == _selectedWeightOption.label
                                              ? const Color(0xFFD1FAE5)
                                              : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: opt.label == _selectedWeightOption.label
                                                ? const Color(0xFF047857)
                                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                            width: opt.label == _selectedWeightOption.label ? 2 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (opt.tag != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: opt.label == _selectedWeightOption.label
                                                      ? const Color(0xFF047857)
                                                      : const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  opt.tag!,
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color: opt.label == _selectedWeightOption.label
                                                        ? Colors.white
                                                        : const Color(0xFF475569),
                                                  ),
                                                ),
                                              )
                                            else
                                              const SizedBox(height: 15),
                                            const SizedBox(height: 6),
                                            Text(
                                              opt.label,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '৳ ${_formatPrice(opt.price)} / pc',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: opt.label == _selectedWeightOption.label
                                                    ? const Color(0xFF047857)
                                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                              ),
                                            ),
                                          ],
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

                    const SizedBox(height: 18),

                    // 6. Custom Cut / Preparation Options
                    if (product.effectiveCutOptions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    isFishOrMeat
                                        ? 'Custom Fish Cut (কাটা ও পরিষ্কার)'
                                        : 'Preparation & Sorting (বাছাই ও প্রস্তুতি)',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Row(
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF059669)),
                                    SizedBox(width: 3),
                                    Text(
                                      'Free Service',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Column(
                              children: [
                                for (final cut in product.effectiveCutOptions)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: InkWell(
                                      onTap: () => setState(() => _selectedCut = cut),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: cut == _selectedCut
                                              ? const Color(0xFFD1FAE5)
                                              : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: cut == _selectedCut
                                                ? const Color(0xFF047857)
                                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                            width: cut == _selectedCut ? 1.8 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              cut == _selectedCut ? Icons.radio_button_checked : Icons.radio_button_off,
                                              color: cut == _selectedCut ? const Color(0xFF047857) : const Color(0xFF94A3B8),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    cut,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    cut.contains('Curry')
                                                        ? 'Descaled, gutted, washed with river water'
                                                        : (cut.contains('Head')
                                                            ? 'Separated belly fat & dorsal pieces, halved head'
                                                            : 'Kept whole on shaved dry ice block'),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (cut.contains('Curry'))
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF064E3B),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'Most Popular',
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
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
                          ],
                        ),
                      ),

                    const SizedBox(height: 18),

                    // 7. Zero-Formalin Guarantee & Lab Report Block
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.science_outlined, color: Color(0xFF047857), size: 20),
                                    SizedBox(width: 6),
                                    Text(
                                      'INDEPENDENT LAB TESTED',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF047857),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF064E3B),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '0.00 ppm',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Zero-Formalin Guarantee',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildCertRow('Sample ID', product.labCertificateId ?? 'Lab Sample #BZ-2024-8841'),
                                  const Divider(height: 16),
                                  _buildCertRow('Methodology', 'Spectrophotometric Assay'),
                                  const Divider(height: 16),
                                  _buildCertRow('Chemical Residue', 'Negative (Zero Detected)'),
                                  const Divider(height: 16),
                                  _buildCertRow('Authorized Officer', 'Dr. A. Karim, Lead Food Biochemist'),
                                  const Divider(height: 16),
                                  _buildCertRow('Storage Compliance', '0°C - 2°C Certified'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Downloading certified QC lab report PDF...'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Color(0xFF047857)),
                                label: const Text(
                                  'View Full Certificate & QC Stamp (PDF)',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 8. Meet Your Fisherman / Farmer Block
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isFishOrMeat ? 'PADMA RIVER ORIGIN' : 'LOCAL HARVEST ORIGIN',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFD97706),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Verified Artisan',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isFishOrMeat ? 'Meet Your Fisherman' : 'Meet Your Local Farmer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: const AssetImage('assets/images/farmer_avatar.jpg'),
                                  backgroundColor: const Color(0xFFD1FAE5),
                                  child: const Icon(Icons.person, color: Color(0xFF047857)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.sellerName.isNotEmpty ? product.sellerName : 'Rafiqul Islam (রফিকুল ইসলাম)',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Chandpur Meghna Mohona · ${product.farmerExperience ?? "24 Years Exp."}',
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                      ),
                                      const SizedBox(height: 2),
                                      const Row(
                                        children: [
                                          Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                                          SizedBox(width: 2),
                                          Text(
                                            '4.9 Artisan Rating · 400+ Catches',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                product.farmerQuote ??
                                    '"I caught this fish around 2:00 AM at the confluence of Padma & Meghna. Within 30 minutes, it was layered with clean ice and sent to BazaarShodai\'s testing van. No chemicals, pure river harvest."',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Cold-Chain Journey of this Product',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            _buildTimelineStep('02:15 AM', 'Harvested from Chandpur Mohona', true),
                            _buildTimelineStep('03:45 AM', 'Formalin & Quality Lab Clearance', true),
                            _buildTimelineStep('05:30 AM', 'Temperature-Controlled Chilled Dispatch', true),
                            _buildTimelineStep('07:15 AM', 'Received at Dhanmondi Hub (Awaiting Cut)', true),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 9. Customer Ratings & Packaging Guarantee
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer Verification',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildScoreCard('Freshness', '5.0'),
                              const SizedBox(width: 8),
                              _buildScoreCard(isFishOrMeat ? 'River Taste' : 'Farm Sweet', '4.9'),
                              const SizedBox(width: 8),
                              _buildScoreCard(isFishOrMeat ? 'Clean Cut' : 'Clean Pack', '5.0'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Tanvir Ahmed · Dhanmondi Road 8', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text('Yesterday', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '"Remarkable taste and authentic fresh aroma! Delivered iced inside the thermal pouch without a hint of freezer odor. Truly formalin free."',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.inventory_2_outlined, color: Color(0xFF1E40AF), size: 22),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Delivered in Biodegradable Ice Box',
                                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A)),
                                      ),
                                      Text(
                                        'Ensures 0°C fresh condition right to your kitchen table.',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 10. Sticky Bottom Checkout Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total (incl. vat)',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                      Text(
                        '৳ ${_formatPrice(totalPrice)}',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32),
                          icon: const Icon(Icons.remove, size: 16),
                          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        ),
                        Text(
                          '$_quantity',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32),
                          icon: const Icon(Icons.add, size: 16),
                          onPressed: _quantity < widget.product.stock
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: widget.product.stock > 0 ? _handleAddToCart : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF047857),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.shopping_cart_outlined, size: 17, color: Colors.white),
                        label: const Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
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
  }

  Widget _buildCertRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep(String time, String title, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 15,
            color: const Color(0xFF059669),
          ),
          const SizedBox(width: 8),
          Text('$time - ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF047857))),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155))),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String label, String score) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Column(
          children: [
            Text(
              score,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
            ),
          ],
        ),
      ),
    );
  }
}
