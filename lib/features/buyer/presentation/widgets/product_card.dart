import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../domain/models/product_model.dart';
import 'auth_prompt_sheet.dart';

/// Redesigned Product Card matching BazaarShodai reference design:
/// - Full upper portion filled by product image with rounded top corners
/// - Red discount pill badge (-X% OFF) on top-left
/// - Circular white heart outline wishlist button on top-right with soft shadow
/// - Dynamic 'X left in stock' badge on bottom-left of image when stock <= 5
/// - Vendor name + emerald verified badge (✔)
/// - Bold 2-line title with high contrast
/// - Unit specification (1 kg, etc.) + Star rating display (★ 4.9)
/// - Bold Bangladeshi currency price (৳ 1,450) + Strikethrough original price (৳ 1,750)
/// - Emerald green '+ Add' button with shopping cart icon
/// - Mint green interactive stepper when added to cart
/// - Responsive dark mode support & guest authentication protection
class ProductCard extends ConsumerStatefulWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _isWishlisted = false;

  void _handleWishlistToggle() {
    final authUser = ref.read(authStateChangesProvider).value;

    if (authUser == null) {
      AuthPromptSheet.show(
        context,
        title: 'Sign In to Save Wishlist',
        message:
            'Create a free account to save ${widget.product.title} to your personal wishlist.',
      );
      return;
    }

    setState(() {
      _isWishlisted = !_isWishlisted;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isWishlisted ? 'Added to wishlist!' : 'Removed from wishlist.',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  void _handleAddToCart() {
    final (success, msg) =
        ref.read(cartProvider.notifier).addItem(widget.product);
    if (!success) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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

  Widget _buildProductImage(ProductModel product) {
    if (product.primaryImage.isNotEmpty) {
      if (product.primaryImage.startsWith('assets/')) {
        return Image.asset(
          product.primaryImage,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
      return Image.network(
        product.primaryImage,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
                color: AppColors.primary,
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => _buildFallbackImage(),
      );
    }
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      'assets/images/tomato_sample.jpg',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => Container(
        color: const Color(0xFFF1F5F9),
        alignment: Alignment.center,
        child: const Icon(
          Icons.shopping_bag_outlined,
          color: AppColors.textMuted,
          size: 32,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartItem = ref.watch(cartProvider.select((s) => s.items[product.id]));
    final int qty = cartItem?.quantity ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Image with Badges
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(17)),
                      child: _buildProductImage(product),
                    ),

                    // Top-Left: Red Discount Pill Badge (-X% OFF)
                    if (product.hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDC2626)
                                    .withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            '-${product.discountPercentage}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),

                    // Top-Right: Circular White Heart Wishlist Button
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _handleWishlistToggle,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 5,
                                  offset: const Offset(0, 1.5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                _isWishlisted
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_outline_rounded,
                                color: _isWishlisted
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF475569),
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom-Left: Stock Pill Badge (Shown when 5 or fewer items remaining)
                    if (product.stock > 0 && product.stock <= 5)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            '${product.stock} left in stock',
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 2. Details & Action Area
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Vendor Row: Store Name + Emerald Verified Badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            product.sellerName.isNotEmpty
                                ? product.sellerName
                                : 'Local Farm',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: Color(0xFF059669),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Product Title (2-line support with ellipsis)
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF0F172A),
                        height: 1.22,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Unit & Rating Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.unit.isNotEmpty ? product.unit : '1 kg',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              (product.rating > 0 ? product.rating : 4.8)
                                  .toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Price (Dark Taka) & Strikethrough Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '৳ ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          _formatPrice(product.price),
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 5),
                          Text(
                            '৳ ${_formatPrice(product.originalPrice!)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Action: Mint Green Stepper or Solid Dark Green '+ Add' Button
                    qty > 0
                        ? Container(
                            height: 34,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF064E3B)
                                  : const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Minus Button (white pill)
                                InkWell(
                                  onTap: () => ref
                                      .read(cartProvider.notifier)
                                      .decrement(product.id),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 28,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.remove,
                                      size: 14,
                                      color: Color(0xFF047857),
                                    ),
                                  ),
                                ),

                                // Centered Quantity Count
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                  child: Text(
                                    '$qty',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF047857),
                                    ),
                                  ),
                                ),

                                // Plus Button (solid dark green pill)
                                InkWell(
                                  onTap: qty >= product.stock
                                      ? () {
                                          ScaffoldMessenger.of(context)
                                              .hideCurrentSnackBar();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Only ${product.stock} units available in stock.'),
                                              duration: const Duration(
                                                  milliseconds: 1200),
                                            ),
                                          );
                                        }
                                      : () => ref
                                          .read(cartProvider.notifier)
                                          .increment(product.id),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 28,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF047857),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF047857)
                                              .withValues(alpha: 0.3),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 14,
                                      color: qty >= product.stock
                                          ? Colors.white54
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _handleAddToCart,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF047857),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF047857)
                                          .withValues(alpha: 0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1.5),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      '+ Add',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.2,
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
      ),
    );
  }
}
