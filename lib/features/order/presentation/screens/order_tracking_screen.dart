import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/order_model.dart';
import '../providers/order_providers.dart';

/// Interactive Order Tracking Screen for BazaarShodai buyers.
/// Provides:
/// - Real-time order status updates via [orderTrackingStreamProvider]
/// - 4-stage vertical timeline stepper with visual cues
/// - Perishable slot & destination address details
/// - Itemized receipt and vendor breakdown
/// - Customer support modal & cancellation option for newly placed orders
/// - Developer/Evaluator status progression controls
class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  final bool isNewOrder;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    this.isNewOrder = false,
  });

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  void _showSupportModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'BazaarShodai Customer Care',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Our Dhaka customer satisfaction team is active daily from 7:00 AM to 11:00 PM.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone, color: AppColors.primary),
                ),
                title: const Text('Direct Hotline: 09612-BAZAAR', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('+880 9612-229227 (Toll Free)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dialing BazaarShodai Care: 09612-229227')),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF2563EB)),
                ),
                title: const Text('Live WhatsApp Chat Support', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('+880 1712-345678'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Connecting to WhatsApp Support...')),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDF2F8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.email_outlined, color: Color(0xFFDB2777)),
                ),
                title: const Text('Email Support', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('care@bazaarshodai.com'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Emailing care@bazaarshodai.com')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCancelOrder(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be reversed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(orderRepositoryProvider).cancelOrder(order.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order has been cancelled.'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _simulateNextStatus(OrderModel order) {
    OrderStatus next;
    switch (order.status) {
      case OrderStatus.placed:
        next = OrderStatus.confirmed;
        break;
      case OrderStatus.confirmed:
        next = OrderStatus.outForDelivery;
        break;
      case OrderStatus.outForDelivery:
        next = OrderStatus.delivered;
        break;
      case OrderStatus.delivered:
        next = OrderStatus.placed;
        break;
      case OrderStatus.cancelled:
        next = OrderStatus.placed;
        break;
    }
    ref.read(orderRepositoryProvider).updateOrderStatus(order.id, next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demo: Updated status to "${next.displayName}"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderTrackingStreamProvider(widget.orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Track Grocery Order',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined),
            tooltip: 'Customer Support',
            onPressed: _showSupportModal,
          ),
          orderAsync.when(
            data: (order) {
              if (order == null) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (val) {
                  if (val == 'simulate') {
                    _simulateNextStatus(order);
                  } else if (val == 'cancel') {
                    _handleCancelOrder(order);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'simulate',
                    child: Row(
                      children: [
                        Icon(Icons.fast_forward, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Demo: Advance Status'),
                      ],
                    ),
                  ),
                  if (order.status == OrderStatus.placed)
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Cancel Order', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off, size: 60, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 12),
                    Text(
                      'Order #${widget.orderId} not found',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Success banner if newly placed
                if (widget.isNewOrder) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF059669), size: 28),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Placed Successfully!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF065F46),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Vendors are preparing your fresh grocery items.',
                                style: TextStyle(color: Color(0xFF047857), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 2. Order Header Card
                _buildHeaderCard(order),
                const SizedBox(height: 16),

                // 3. Live 4-Step Stepper
                _buildTrackingTimeline(order),
                const SizedBox(height: 16),

                // 4. Delivery Destination & Slot
                _buildDeliveryInfoCard(order),
                const SizedBox(height: 16),

                // 5. Ordered Items List
                _buildItemsListCard(order),
                const SizedBox(height: 16),

                // 6. Payment & Bill Breakdown
                _buildPaymentSummaryCard(order),
                const SizedBox(height: 24),

                // 7. Support & Cancellation Bar
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showSupportModal,
                        icon: const Icon(Icons.help_outline, color: AppColors.primary),
                        label: const Text(
                          'Need Help?',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    if (order.status == OrderStatus.placed) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleCancelOrder(order),
                          icon: const Icon(Icons.close, color: Colors.white, size: 18),
                          label: const Text(
                            'Cancel Order',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Error loading order: $err'),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ORDER ID',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '#${order.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 14, color: Color(0xFF94A3B8)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Copy ID',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: order.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order ID copied!'), duration: Duration(seconds: 1)),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: order.status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: order.status.color,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                'Slot: ${order.deliverySlot}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const Spacer(),
              Text(
                'Date: ${order.deliveryDate}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingTimeline(OrderModel order) {
    final stages = [
      {'title': 'Order Placed', 'desc': 'Order has been received by BazaarShodai', 'icon': Icons.assignment_turned_in_outlined},
      {'title': 'Confirmed & Packing', 'desc': 'Vendors are selecting and packing fresh items', 'icon': Icons.inventory_2_outlined},
      {'title': 'Out for Delivery', 'desc': 'Delivery hero dispatched to your address', 'icon': Icons.delivery_dining_outlined},
      {'title': 'Delivered', 'desc': 'Package safely delivered at your doorstep', 'icon': Icons.home_outlined},
    ];

    final currentStep = order.status.stepIndex; // 0, 1, 2, 3, or -1 for cancelled

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
            'Order Status',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),
          if (order.status == OrderStatus.cancelled) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cancel, color: Color(0xFFDC2626)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This order was cancelled. If you were charged, your refund is being processed.',
                      style: TextStyle(color: Color(0xFF991B1B), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stages.length,
              itemBuilder: (ctx, i) {
                final isCompleted = currentStep > i;
                final isCurrent = currentStep == i;
                final isFuture = currentStep < i;

                final Color circleColor = isCompleted
                    ? const Color(0xFF059669)
                    : isCurrent
                        ? AppColors.primary
                        : const Color(0xFFCBD5E1);

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? const Color(0xFFECFDF5)
                                  : isCurrent
                                      ? AppColors.primarySurface
                                      : const Color(0xFFF8FAFC),
                              shape: BoxShape.circle,
                              border: Border.all(color: circleColor, width: isCurrent ? 2 : 1.5),
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.check
                                  : (stages[i]['icon'] as IconData),
                              size: 16,
                              color: circleColor,
                            ),
                          ),
                          if (i < stages.length - 1)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: isCompleted ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stages[i]['title'] as String,
                                style: TextStyle(
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 14,
                                  color: isFuture ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                stages[i]['desc'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isFuture ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoCard(OrderModel order) {
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
          const Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'Delivery Destination',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${order.deliveryAddress.recipientName} (${order.deliveryAddress.label})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            order.deliveryAddress.formattedAddress,
            style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Contact: ${order.deliveryAddress.phoneNumber}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          if (order.deliveryInstructions != null && order.deliveryInstructions!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Rider Note: "${order.deliveryInstructions}"',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsListCard(OrderModel order) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Items in Order',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Text(
                '${order.totalItemCount} total items',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 44,
                      height: 44,
                      color: const Color(0xFFF1F5F9),
                      child: item.image.isNotEmpty
                          ? Image.network(
                              item.image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.shopping_basket, color: Color(0xFF94A3B8)),
                            )
                          : const Icon(Icons.shopping_basket, color: Color(0xFF94A3B8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${item.quantity} x ${item.unit} (${item.sellerName})',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '৳ ${item.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard(OrderModel order) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Details',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.paymentMethod,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBillRow('Subtotal', '৳ ${order.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 6),
          _buildBillRow(
            'Delivery Charge',
            order.deliveryFee == 0 ? 'FREE' : '৳ ${order.deliveryFee.toStringAsFixed(0)}',
            isGreen: order.deliveryFee == 0,
          ),
          if (order.discount > 0) ...[
            const SizedBox(height: 6),
            _buildBillRow('Promo Discount', '-৳ ${order.discount.toStringAsFixed(0)}', isGreen: true),
          ],
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                '৳ ${order.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isGreen ? const Color(0xFF059669) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
