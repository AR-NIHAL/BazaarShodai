import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/product_model.dart';
import 'auth_prompt_sheet.dart';

/// Pixel-perfect Product Card matching BazaarShodai reference design:
/// - Red discount pill badge (-20%)
/// - Circular wishlist button
/// - Bold title
/// - Verified merchant shop badge with green checkmark (✔)
/// - Red current price (৳) with strikethrough original price
/// - Solid emerald green '+ Add' pill button
/// - Guest-authentication protection on interactive actions
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
        message: 'Create a free account to save ${widget.product.title} to your personal wishlist.',
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
    final authUser = ref.read(authStateChangesProvider).value;

    if (authUser == null) {
      AuthPromptSheet.show(
        context,
        title: 'Sign In to Add to Cart',
        message: 'Sign in to add fresh groceries to your cart and proceed to doorstep checkout.',
      );
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.title} added to cart!'),
        backgroundColor: AppColors.primaryDark,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              // 1. Top Image with Badges
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Container(
                      height: 130,
                      width: double.infinity,
                      color: AppColors.surfaceVariant,
                      child: product.primaryImage.isNotEmpty
                          ? Image.network(
                              product.primaryImage,
                              fit: BoxFit.cover,
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
                              errorBuilder: (_, _, _) => const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AppColors.textMuted,
                                  size: 32,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                color: AppColors.textMuted,
                                size: 32,
                              ),
                            ),
                    ),
                  ),

                  // Top-Left: Red Discount Pill Badge (-20%)
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          '-${product.discountPercentage}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),

                  // Top-Right: Heart outline in circle
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: _handleWishlistToggle,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isWishlisted ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: _isWishlisted ? const Color(0xFFE53935) : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Details & Action Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Verified Seller Line
                          Row(
                            children: [
                              const Icon(
                                Icons.storefront_outlined,
                                size: 13,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  product.sellerName.isNotEmpty
                                      ? product.sellerName
                                      : 'Verified Seller',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.check_circle,
                                size: 13,
                                color: Color(0xFF059669),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Price (Red Taka) & + Add Button Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Price in Red + Strikethrough
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  const Text(
                                    '৳ ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFE53935),
                                    ),
                                  ),
                                  Text(
                                    _formatPrice(product.price),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFE53935),
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
                                  ),
                                ),
                            ],
                          ),

                          // Solid Green '+ Add' Button
                          InkWell(
                            onTap: _handleAddToCart,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF059669).withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 14, color: Colors.white),
                                  SizedBox(width: 3),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
