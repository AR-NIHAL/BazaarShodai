import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../domain/models/product_model.dart';
import 'auth_prompt_sheet.dart';

/// Pixel-perfect Product Card matching BazaarShodai reference design:
/// - Full upper portion filled by product image (no blank spaces)
/// - Red discount pill badge (-20%) on top-left
/// - Crisp white heart outline wishlist button on top-right with soft shadow
/// - Tightly grouped details: Title, Farmer Avatar + Store + Verified Badge (✔)
/// - Red Bengali currency price (৳ 80) + Strikethrough original price (৳ 100)
/// - Emerald green '+ Add' button with touch ripple & interactive quantity stepper
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
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Image - EXPANDED to fill upper card naturally (NO blank space)
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(15)),
                      child: _buildProductImage(product),
                    ),

                    // Top-Left: Red Discount Pill Badge (-20%)
                    if (product.hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE53935)
                                    .withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            '-${product.discountPercentage}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),

                    // Top-Right: Crisp White Heart Outline
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _handleWishlistToggle,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              _isWishlisted
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_outline_rounded,
                              color: _isWishlisted
                                  ? const Color(0xFFE53935)
                                  : Colors.white,
                              size: 22,
                              shadows: const [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 6,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Details & Action Area - Tightly grouped (NO blank gap)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1E293B),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Vendor Row: [Farmer Avatar] Green Valley Farm [✔]
                    Row(
                      children: [
                        Container(
                          width: 17,
                          height: 17,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFCBD5E1),
                              width: 0.6,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/farmer_avatar.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 11,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            product.sellerName.isNotEmpty
                                ? product.sellerName
                                : 'Green Valley Farm',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: Color(0xFF059669),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Price (Red Taka) & + Add Button Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price in Red + Strikethrough
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                const Text(
                                  '৳ ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFE53935),
                                  ),
                                ),
                                Text(
                                  _formatPrice(product.price),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFE53935),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                            if (product.hasDiscount)
                              Text(
                                '৳ ${_formatPrice(product.originalPrice!)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Color(0xFF94A3B8),
                                ),
                              )
                            else
                              const SizedBox(height: 14),
                          ],
                        ),

                        // Quantity Stepper or Solid Green '+ Add' Button
                        qty > 0
                            ? Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF059669)
                                          .withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () => ref
                                          .read(cartProvider.notifier)
                                          .decrement(product.id),
                                      borderRadius:
                                          const BorderRadius.horizontal(
                                              left: Radius.circular(10)),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 6),
                                        child: Icon(Icons.remove,
                                            size: 14, color: Colors.white),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: Text(
                                        '$qty',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
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
                                      borderRadius:
                                          const BorderRadius.horizontal(
                                              right: Radius.circular(10)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 6),
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 7.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF059669)
                                              .withValues(alpha: 0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add_rounded,
                                            size: 16, color: Colors.white),
                                        SizedBox(width: 3),
                                        Text(
                                          'Add',
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
