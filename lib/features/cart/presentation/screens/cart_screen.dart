import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../checkout/presentation/screens/checkout_screen.dart';
import '../../domain/models/cart_item_model.dart';
import '../../domain/models/cart_state.dart';
import '../providers/cart_providers.dart';

/// Production-ready Cart Screen for BazaarShodai buyers.
/// Features:
/// - Dynamic item list with vendor badges
/// - Real-time free delivery threshold progress bar
/// - Interactive quantity adjustments & item deletion
/// - Coupon / Promo code validation (SHODAI50, BAZAAR10)
/// - Comprehensive order bill breakdown (subtotal, savings, delivery fee, total)
/// - Sticky bottom checkout bar
class CartScreen extends ConsumerStatefulWidget {
  final VoidCallback? onExploreTap;

  const CartScreen({super.key, this.onExploreTap});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  bool _isApplyingCoupon = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _handleApplyCoupon() {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isApplyingCoupon = true);
    final (success, message) = ref.read(cartProvider.notifier).applyCoupon(code);
    setState(() => _isApplyingCoupon = false);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.primary : AppColors.error,
      ),
    );

    if (success) {
      _couponController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    if (cartState.isEmpty) {
      return _buildEmptyCartView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Shopping Cart',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              '${cartState.totalItemsCount} items from ${cartState.uniqueSellers.length} vendor${cartState.uniqueSellers.length > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Shopping Cart?'),
                  content: const Text('Are you sure you want to remove all items from your cart?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () {
                        ref.read(cartProvider.notifier).clearCart();
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.error),
            label: const Text('Clear', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Free Delivery Progress Bar
          SliverToBoxAdapter(
            child: _buildFreeDeliveryBar(cartState),
          ),

          // 2. Items List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = cartState.items.values.elementAt(index);
                  return _buildCartItemCard(item);
                },
                childCount: cartState.items.length,
              ),
            ),
          ),

          // 3. Coupon Voucher Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildCouponSection(cartState),
            ),
          ),

          // 4. Order Summary Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: _buildOrderSummaryCard(cartState),
            ),
          ),
        ],
      ),
      // 5. Sticky Bottom Checkout Bar
      bottomSheet: _buildStickyCheckoutBar(cartState),
    );
  }

  // --- Free Delivery Banner ---
  Widget _buildFreeDeliveryBar(CartState cartState) {
    final bool isFree = cartState.hasFreeDelivery;
    final double needed = cartState.amountNeededForFreeDelivery;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isFree ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFree ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFree ? Icons.check_circle_rounded : Icons.local_shipping_outlined,
                color: isFree ? const Color(0xFF059669) : const Color(0xFFD97706),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFree
                      ? 'Congratulations! You unlocked FREE Delivery! 🚚'
                      : 'Add ৳ ${needed.toStringAsFixed(0)} more to get FREE Delivery!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isFree ? const Color(0xFF065F46) : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: cartState.freeDeliveryProgress,
              minHeight: 6,
              backgroundColor: isFree ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
              color: isFree ? const Color(0xFF059669) : const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }

  // --- Cart Item Card ---
  Widget _buildCartItemCard(CartItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 76,
              height: 76,
              color: const Color(0xFFF1F5F9),
              child: item.image.isNotEmpty
                  ? Image.network(
                      item.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.eco_rounded,
                        color: Color(0xFF059669),
                        size: 32,
                      ),
                    )
                  : const Icon(
                      Icons.eco_rounded,
                      color: Color(0xFF059669),
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Details & Controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),

                // Seller / Vendor name
                Row(
                  children: [
                    const Icon(Icons.storefront_outlined, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        item.sellerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Price & Inline Counter Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '৳ ${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        if (item.hasDiscount)
                          Text(
                            '৳ ${item.originalPrice!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),

                    // Counter `[-] [ qty ] [+]`
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCounterBtn(
                            icon: item.quantity == 1 ? Icons.delete_outline : Icons.remove,
                            color: item.quantity == 1 ? AppColors.error : AppColors.textPrimary,
                            onTap: () {
                              ref.read(cartProvider.notifier).decrement(item.productId);
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          _buildCounterBtn(
                            icon: Icons.add,
                            color: item.quantity >= item.stock ? AppColors.textMuted : AppColors.primary,
                            onTap: item.quantity >= item.stock
                                ? null
                                : () {
                                    final (success, msg) = ref
                                        .read(cartProvider.notifier)
                                        .increment(item.productId);
                                    if (!success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(msg),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterBtn({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  // --- Coupon Voucher Section ---
  Widget _buildCouponSection(CartState cartState) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.confirmation_number_outlined, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Apply Promo Code / Coupon',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (cartState.appliedCoupon != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coupon "${cartState.appliedCoupon}" Applied (-৳ ${cartState.couponDiscount.toStringAsFixed(0)})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).removeCoupon();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Remove', style: TextStyle(color: AppColors.error, fontSize: 12)),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter coupon (e.g. SHODAI50)',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isApplyingCoupon ? null : _handleApplyCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isApplyingCoupon
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Apply'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // --- Order Summary / Bill Details ---
  Widget _buildOrderSummaryCard(CartState cartState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Bill Summary',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Items Subtotal', '৳ ${cartState.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 8),

          _buildSummaryRow(
            'Delivery Fee',
            cartState.deliveryFee == 0 ? 'FREE' : '৳ ${cartState.deliveryFee.toStringAsFixed(0)}',
            isGreen: cartState.deliveryFee == 0,
          ),
          const SizedBox(height: 8),

          if (cartState.productSavings > 0) ...[
            _buildSummaryRow(
              'Product Discount',
              '-৳ ${cartState.productSavings.toStringAsFixed(0)}',
              isGreen: true,
            ),
            const SizedBox(height: 8),
          ],

          if (cartState.couponDiscount > 0) ...[
            _buildSummaryRow(
              'Coupon Discount',
              '-৳ ${cartState.couponDiscount.toStringAsFixed(0)}',
              isGreen: true,
            ),
            const SizedBox(height: 8),
          ],

          const Divider(height: 20, color: Color(0xFFE2E8F0)),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Payable',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
              ),
              Text(
                '৳ ${cartState.totalPayable.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),

          if (cartState.totalSavings > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🎉 You are saving ৳ ${cartState.totalSavings.toStringAsFixed(0)} on this order!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF047857),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: isGreen ? const Color(0xFF059669) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // --- Sticky Bottom Checkout Bar ---
  Widget _buildStickyCheckoutBar(CartState cartState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Payable',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                Text(
                  '৳ ${cartState.totalPayable.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleProceedToCheckout(cartState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Proceed to Checkout',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleProceedToCheckout(CartState cartState) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CheckoutScreen(),
      ),
    );
  }

  // --- Empty Cart View ---
  Widget _buildEmptyCartView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_basket_outlined,
                size: 72,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Shopping Cart is Empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explore farm-fresh produce, organic dairy, and river fish directly from local farmers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onExploreTap,
              icon: const Icon(Icons.storefront_outlined, color: Colors.white),
              label: const Text(
                'Explore Fresh Produce',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF047857),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
