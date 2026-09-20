import 'cart_item_model.dart';

/// Immutable state representing the user's active shopping cart.
class CartState {
  final Map<String, CartItemModel> items;
  final String? appliedCoupon;
  final double couponDiscount;

  /// Free delivery threshold in Bangladeshi Taka
  static const double freeDeliveryThreshold = 1000.0;

  /// Standard delivery charge in Bangladeshi Taka
  static const double standardDeliveryFee = 50.0;

  const CartState({
    this.items = const {},
    this.appliedCoupon,
    this.couponDiscount = 0.0,
  });

  /// Total count of individual units in cart
  int get totalItemsCount => items.values.fold(0, (sum, i) => sum + i.quantity);

  /// Subtotal based on current effective item prices
  double get subtotal => items.values.fold(0.0, (sum, i) => sum + i.totalPrice);

  /// Subtotal based on original prices before product discounts
  double get totalOriginalPrice => items.values.fold(0.0, (sum, i) => sum + i.totalOriginalPrice);

  /// Savings strictly from product discounts
  double get productSavings => items.values.fold(0.0, (sum, i) => sum + i.savings);

  /// Total savings combining product discounts and coupons
  double get totalSavings => productSavings + couponDiscount;

  /// Delivery fee: Free if subtotal >= 1000 or empty, else 50 Taka
  double get deliveryFee {
    if (isEmpty || subtotal >= freeDeliveryThreshold) {
      return 0.0;
    }
    return standardDeliveryFee;
  }

  /// Whether current order qualifies for free delivery
  bool get hasFreeDelivery => subtotal >= freeDeliveryThreshold && isNotEmpty;

  /// Amount in Taka remaining to unlock free delivery
  double get amountNeededForFreeDelivery =>
      (freeDeliveryThreshold - subtotal).clamp(0.0, freeDeliveryThreshold);

  /// Progress ratio towards free delivery (0.0 to 1.0)
  double get freeDeliveryProgress =>
      (subtotal / freeDeliveryThreshold).clamp(0.0, 1.0);

  /// Net payable amount after discounts and delivery fee
  double get totalPayable {
    if (isEmpty) return 0.0;
    final payable = subtotal - couponDiscount + deliveryFee;
    return payable.clamp(0.0, double.infinity);
  }

  /// Unique vendor names providing items in this cart
  Set<String> get uniqueSellers => items.values.map((i) => i.sellerName).toSet();

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  CartState copyWith({
    Map<String, CartItemModel>? items,
    String? appliedCoupon,
    double? couponDiscount,
    bool clearCoupon = false,
  }) {
    return CartState(
      items: items ?? this.items,
      appliedCoupon: clearCoupon ? null : (appliedCoupon ?? this.appliedCoupon),
      couponDiscount: clearCoupon ? 0.0 : (couponDiscount ?? this.couponDiscount),
    );
  }
}
