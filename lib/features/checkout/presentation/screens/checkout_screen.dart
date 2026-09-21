import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../cart/domain/models/cart_state.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../domain/models/address_model.dart';
import '../../domain/models/delivery_slot_model.dart';
import '../providers/checkout_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../order/domain/models/order_model.dart';
import '../../../order/presentation/providers/order_providers.dart';
import '../../../order/presentation/screens/order_tracking_screen.dart';

/// Production Checkout Screen for BazaarShodai buyers.
/// Provides:
/// - Hyperlocal delivery address selector & quick add address modal
/// - Time-slot picker (Morning, Evening, Express) for fresh produce
/// - Cash on Delivery (COD) and simulated bKash / Nagad payment options
/// - Special rider instructions
/// - Final bill summary with slot adjustments
/// - Order placement & confirmation modal
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _showAddressPicker() {
    final addresses = ref.read(addressesProvider);
    final selected = ref.read(checkoutProvider).selectedAddress;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
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
                        'Select Delivery Address',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...addresses.map((addr) {
                    final isCurrent = selected?.id == addr.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isCurrent ? const Color(0xFFECFDF5) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrent ? AppColors.primary : const Color(0xFFE2E8F0),
                          width: isCurrent ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCurrent ? AppColors.primary : const Color(0xFFF1F5F9),
                          child: Icon(
                            addr.label == 'Office' ? Icons.business : Icons.home,
                            color: isCurrent ? Colors.white : AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          '${addr.label} (${addr.recipientName})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${addr.formattedAddress}\nPhone: ${addr.phoneNumber}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: isCurrent
                            ? const Icon(Icons.check_circle, color: AppColors.primary)
                            : null,
                        onTap: () {
                          ref.read(checkoutProvider.notifier).setAddress(addr);
                          Navigator.of(ctx).pop();
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showAddNewAddressModal();
                    },
                    icon: const Icon(Icons.add, color: AppColors.primary),
                    label: const Text(
                      'Add New Delivery Address',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddNewAddressModal() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: 'Customer');
    final phoneCtrl = TextEditingController(text: '01712345678');
    final streetCtrl = TextEditingController();
    String selectedArea = AddressModel.popularAreas[0];
    String label = 'Home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Address in Dhaka',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: ['Home', 'Office', 'Other'].map((l) {
                        final isSel = label == l;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(l),
                            selected: isSel,
                            selectedColor: const Color(0xFFD1FAE5),
                            labelStyle: TextStyle(
                              color: isSel ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) => setModalState(() => label = l),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Recipient Name'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone Number (+880)'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedArea,
                      decoration: const InputDecoration(labelText: 'Area / Neighborhood'),
                      items: AddressModel.popularAreas
                          .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedArea = v);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: streetCtrl,
                      decoration: const InputDecoration(
                        labelText: 'House #, Road #, Block/Sector',
                        hintText: 'e.g. House 12, Road 4, Sector 7',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final newAddr = AddressModel(
                            id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
                            userId: 'current_user',
                            label: label,
                            recipientName: nameCtrl.text.trim(),
                            phoneNumber: phoneCtrl.text.trim(),
                            street: streetCtrl.text.trim(),
                            area: selectedArea,
                            city: 'Dhaka',
                            isDefault: true,
                          );
                          ref.read(addressesProvider.notifier).addAddress(newAddr);
                          ref.read(checkoutProvider.notifier).setAddress(newAddr);
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Delivery address saved!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Address'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handlePlaceOrder(CartState cartState, CheckoutState checkoutState) async {
    if (_isSubmitting) return;

    if (checkoutState.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or add a delivery address.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final double extraFee = checkoutState.selectedSlot.extraFee;
      final double finalPayable = cartState.totalPayable + extraFee;
      final authUser = ref.read(authStateChangesProvider).value;
      final buyerId = authUser?.uid ?? 'guest_user';
      final vendorIds = cartState.items.values.map((i) => i.sellerId).toSet().toList();

      final order = OrderModel(
        id: '',
        buyerId: buyerId,
        buyerName: checkoutState.selectedAddress!.recipientName,
        buyerPhone: checkoutState.selectedAddress!.phoneNumber,
        deliveryAddress: checkoutState.selectedAddress!,
        items: cartState.items.values.toList(),
        vendorIds: vendorIds,
        subtotal: cartState.subtotal,
        deliveryFee: cartState.deliveryFee + extraFee,
        discount: cartState.couponDiscount,
        totalAmount: finalPayable,
        paymentMethod: checkoutState.selectedPaymentMethod.displayName,
        paymentStatus: checkoutState.selectedPaymentMethod == PaymentMethod.cashOnDelivery ? 'pending' : 'paid',
        deliveryDate: 'Today',
        deliverySlot: checkoutState.selectedSlot.title,
        deliveryInstructions: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        status: OrderStatus.placed,
        createdAt: DateTime.now(),
        estimatedDeliveryTime: DateTime.now().add(const Duration(hours: 2)),
      );

      final String placedOrderId = await ref.read(orderRepositoryProvider).placeOrder(order);

      // Clear cart
      ref.read(cartProvider.notifier).clearCart();

      if (!mounted) return;

      // Navigate to live Order Tracking
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(
            orderId: placedOrderId,
            isNewOrder: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final checkoutState = ref.watch(checkoutProvider);
    final double extraFee = checkoutState.selectedSlot.extraFee;
    final double finalPayable = cartState.totalPayable + extraFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Doorstep Checkout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Delivery Address Card
            _buildSectionHeader('1. Delivery Address', Icons.location_on_outlined),
            const SizedBox(height: 8),
            _buildAddressCard(checkoutState.selectedAddress),
            const SizedBox(height: 20),

            // 2. Delivery Time Slot
            _buildSectionHeader('2. Perishable Delivery Slot', Icons.access_time_rounded),
            const SizedBox(height: 8),
            _buildSlotSelector(checkoutState),
            const SizedBox(height: 20),

            // 3. Payment Method
            _buildSectionHeader('3. Payment Method', Icons.payment_outlined),
            const SizedBox(height: 8),
            _buildPaymentSelector(checkoutState),
            const SizedBox(height: 20),

            // 4. Special Rider Instructions
            _buildSectionHeader('4. Delivery Notes (Optional)', Icons.notes_outlined),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'e.g. Leave package with apartment guard, call on arrival',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 5. Final Order Summary
            _buildSectionHeader('5. Order Summary', Icons.receipt_long_outlined),
            const SizedBox(height: 8),
            _buildFinalSummaryCard(cartState, extraFee, finalPayable),
          ],
        ),
      ),
      bottomSheet: _buildBottomBar(cartState, checkoutState, finalPayable),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(AddressModel? address) {
    if (address == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('No address selected', style: TextStyle(color: AppColors.textSecondary)),
            ElevatedButton(
              onPressed: _showAddNewAddressModal,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Add Address'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      address.label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    address.recipientName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              TextButton(
                onPressed: _showAddressPicker,
                child: const Text('Change', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            address.formattedAddress,
            style: const TextStyle(color: Color(0xFF334155), fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            'Phone: ${address.phoneNumber}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotSelector(CheckoutState state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: DeliverySlot.defaultSlots.map((slot) {
          final isSelected = state.selectedSlot.id == slot.id;
          return InkWell(
            onTap: () => ref.read(checkoutProvider.notifier).setDeliverySlot(slot),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    slot.icon,
                    color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              slot.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '(${slot.timeRange})',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          slot.subtitle,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  if (slot.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: slot.extraFee > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        slot.badge!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: slot.extraFee > 0 ? const Color(0xFF92400E) : const Color(0xFF065F46),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentSelector(CheckoutState state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: PaymentMethod.values.map((method) {
          final isSelected = state.selectedPaymentMethod == method;
          return InkWell(
            onTap: () => ref.read(checkoutProvider.notifier).setPaymentMethod(method),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    method == PaymentMethod.cashOnDelivery
                        ? Icons.payments_outlined
                        : Icons.account_balance_wallet_outlined,
                    color: method.brandColor,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              method.displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            if (method == PaymentMethod.cashOnDelivery) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Popular',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          method.subtitle,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFinalSummaryCard(CartState cart, double extraFee, double finalPayable) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildBillRow('Items Total (${cart.totalItemsCount} units)', '৳ ${cart.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 6),
          _buildBillRow(
            'Delivery Charge',
            cart.deliveryFee == 0 ? 'FREE' : '৳ ${cart.deliveryFee.toStringAsFixed(0)}',
            isGreen: cart.deliveryFee == 0,
          ),
          if (extraFee > 0) ...[
            const SizedBox(height: 6),
            _buildBillRow('Express Dispatch Fee', '৳ ${extraFee.toStringAsFixed(0)}'),
          ],
          if (cart.couponDiscount > 0) ...[
            const SizedBox(height: 6),
            _buildBillRow('Coupon Savings', '-৳ ${cart.couponDiscount.toStringAsFixed(0)}', isGreen: true),
          ],
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Payable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                '৳ ${finalPayable.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
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
            fontWeight: FontWeight.bold,
            color: isGreen ? const Color(0xFF059669) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(CartState cart, CheckoutState checkout, double finalPayable) {
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
                const Text('Amount to Pay', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Text(
                  '৳ ${finalPayable.toStringAsFixed(0)}',
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
                onPressed: _isSubmitting ? null : () => _handlePlaceOrder(cart, checkout),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Confirm & Place Order',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
