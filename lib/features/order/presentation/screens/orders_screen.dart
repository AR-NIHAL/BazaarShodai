import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../buyer/domain/models/product_model.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../domain/models/order_model.dart';
import '../providers/order_providers.dart';
import 'order_tracking_screen.dart';

/// Production Orders Screen for BazaarShodai buyers.
/// Provides dual tabs:
/// - Active Orders: In-flight grocery orders with live progress and tracking shortcuts.
/// - Past Orders: Delivered and cancelled orders with receipts and 1-tap re-ordering.
class OrdersScreen extends ConsumerStatefulWidget {
  final VoidCallback? onExploreTap;

  const OrdersScreen({super.key, this.onExploreTap});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleReorder(OrderModel order) {
    for (final item in order.items) {
      final product = ProductModel(
        id: item.productId,
        title: item.title,
        description: '',
        price: item.price,
        stock: 99,
        category: 'Grocery',
        unit: item.unit,
        imageUrls: item.image.isNotEmpty ? [item.image] : [],
        sellerId: item.sellerId,
        sellerName: item.sellerName,
      );
      ref.read(cartProvider.notifier).addItem(product, quantity: item.quantity);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${order.items.length} items re-added to your cart!'),
        backgroundColor: AppColors.primary,
        action: SnackBarAction(
          label: 'Open Cart',
          textColor: Colors.white,
          onPressed: () {
            // Cart navigation can be handled or explored
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeOrdersAsync = ref.watch(activeOrdersProvider);
    final pastOrdersAsync = ref.watch(pastOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Grocery Orders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Active Orders'),
            Tab(text: 'Past Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Active Orders
          activeOrdersAsync.when(
            data: (orders) => _buildOrdersList(orders, isActiveTab: true),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading orders: $err')),
          ),

          // Tab 2: Past Orders
          pastOrdersAsync.when(
            data: (orders) => _buildOrdersList(orders, isActiveTab: false),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading past orders: $err')),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders, {required bool isActiveTab}) {
    if (orders.isEmpty) {
      return _buildEmptyState(
        icon: isActiveTab ? Icons.shopping_bag_outlined : Icons.receipt_long_outlined,
        title: isActiveTab ? 'No Active Orders' : 'No Past Orders Yet',
        subtitle: isActiveTab
            ? 'You do not have any orders in progress right now. Explore farm-fresh produce!'
            : 'Completed and past grocery orders will be logged here for easy re-ordering.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order, isActive: isActiveTab);
      },
    );
  }

  Widget _buildOrderCard(OrderModel order, {required bool isActive}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order ID + Status Pill
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.id}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.deliveryDate} • ${order.deliverySlot}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: order.status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: order.status.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Body: Item previews & Thumbnails
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Thumbnails row (up to 3)
                SizedBox(
                  height: 48,
                  child: Row(
                    children: order.items.take(3).map((item) {
                      return Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: item.image.isNotEmpty
                              ? Image.network(
                                  item.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.shopping_basket, size: 20, color: Color(0xFF94A3B8)),
                                )
                              : const Icon(Icons.shopping_basket, size: 20, color: Color(0xFF94A3B8)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.totalItemCount} Items',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        order.items.map((i) => i.title).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Text(
                  '৳ ${order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Actions Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                if (!isActive) ...[
                  // Re-order button for past orders
                  OutlinedButton.icon(
                    onPressed: () => _handleReorder(order),
                    icon: const Icon(Icons.repeat, size: 16, color: AppColors.primary),
                    label: const Text(
                      'Re-order',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                  const Spacer(),
                ],
                if (isActive) const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderTrackingScreen(orderId: order.id),
                      ),
                    );
                  },
                  icon: Icon(
                    isActive ? Icons.navigation_outlined : Icons.receipt_long,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    isActive ? 'Track Live Order' : 'View Receipt',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? AppColors.primary : const Color(0xFF334155),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (widget.onExploreTap != null) {
                  widget.onExploreTap!();
                } else {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Start Shopping Fresh Goods'),
            ),
          ],
        ),
      ),
    );
  }
}
