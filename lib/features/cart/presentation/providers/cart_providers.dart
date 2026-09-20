import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../buyer/domain/models/product_model.dart';
import '../../domain/models/cart_item_model.dart';
import '../../domain/models/cart_state.dart';

/// Centralized Riverpod Notifier managing shopping cart state,
/// persistence, stock boundaries, and coupon validations.
class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    _loadCartFromStorage();
    return const CartState();
  }

  /// Loads previously saved cart items from local device storage
  Future<void> _loadCartFromStorage() async {
    try {
      final jsonStr = await LocalStorageService.getCartJson();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
        final Map<String, CartItemModel> loadedItems = {};
        for (final itemMap in list) {
          final item = CartItemModel.fromMap(itemMap as Map<String, dynamic>);
          if (item.productId.isNotEmpty && item.quantity > 0) {
            loadedItems[item.productId] = item;
          }
        }
        state = state.copyWith(items: loadedItems);
      }
    } catch (_) {}
  }

  /// Saves current cart items to local device storage asynchronously
  Future<void> _persistCart() async {
    try {
      final list = state.items.values.map((i) => i.toMap()).toList();
      final jsonStr = jsonEncode(list);
      await LocalStorageService.saveCartJson(jsonStr);
    } catch (_) {}
  }

  /// Adds a product to the cart or increments if already present.
  /// Returns a record `(bool success, String message)` for UI feedback.
  (bool, String) addItem(ProductModel product, {int quantity = 1}) {
    if (product.stock <= 0) {
      return (false, '${product.title} is currently out of stock.');
    }

    final currentItem = state.items[product.id];
    final currentQty = currentItem?.quantity ?? 0;
    final newQty = currentQty + quantity;

    if (newQty > product.stock) {
      return (false, 'Only ${product.stock} units available in stock.');
    }

    final updatedItems = Map<String, CartItemModel>.from(state.items);
    updatedItems[product.id] = CartItemModel(
      productId: product.id,
      title: product.title,
      image: product.primaryImage,
      price: product.price,
      originalPrice: product.originalPrice,
      quantity: newQty,
      unit: product.unit.isNotEmpty ? product.unit : '1 kg',
      sellerId: product.sellerId,
      sellerName: product.sellerName.isNotEmpty ? product.sellerName : 'Verified Vendor',
      stock: product.stock,
    );

    state = state.copyWith(items: updatedItems);
    _persistCart();
    return (true, 'Added ${product.title} to cart');
  }

  /// Increments quantity of an existing item in cart, respecting stock bounds.
  (bool, String) increment(String productId) {
    final currentItem = state.items[productId];
    if (currentItem == null) return (false, 'Item not found in cart.');

    if (currentItem.quantity >= currentItem.stock) {
      return (false, 'Maximum stock limit reached (${currentItem.stock}).');
    }

    final updatedItems = Map<String, CartItemModel>.from(state.items);
    updatedItems[productId] = currentItem.copyWith(quantity: currentItem.quantity + 1);

    state = state.copyWith(items: updatedItems);
    _persistCart();
    return (true, 'Quantity updated');
  }

  /// Decrements quantity of an existing item in cart, removing if reaching 0.
  void decrement(String productId) {
    final currentItem = state.items[productId];
    if (currentItem == null) return;

    final updatedItems = Map<String, CartItemModel>.from(state.items);
    if (currentItem.quantity <= 1) {
      updatedItems.remove(productId);
    } else {
      updatedItems[productId] = currentItem.copyWith(quantity: currentItem.quantity - 1);
    }

    state = state.copyWith(items: updatedItems);
    _persistCart();
  }

  /// Removes an item completely from cart.
  void removeItem(String productId) {
    if (!state.items.containsKey(productId)) return;
    final updatedItems = Map<String, CartItemModel>.from(state.items)..remove(productId);
    state = state.copyWith(items: updatedItems);
    _persistCart();
  }

  /// Clears all items in the cart and resets storage.
  void clearCart() {
    state = const CartState();
    LocalStorageService.clearCartData();
  }

  /// Applies a promotional coupon code.
  /// Supported coupons:
  /// - `SHODAI50`: ৳ 50 off on orders >= ৳ 400
  /// - `BAZAAR10`: 10% off (up to ৳ 100) on orders >= ৳ 300
  /// - `FREEDELIVERY`: Waives standard delivery fee
  (bool, String) applyCoupon(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (state.isEmpty) {
      return (false, 'Your shopping cart is empty.');
    }

    if (cleanCode == 'SHODAI50') {
      if (state.subtotal < 400) {
        return (false, 'Minimum order of ৳ 400 required for SHODAI50.');
      }
      state = state.copyWith(
        appliedCoupon: cleanCode,
        couponDiscount: 50.0,
      );
      return (true, '৳ 50 coupon discount applied!');
    } else if (cleanCode == 'BAZAAR10') {
      if (state.subtotal < 300) {
        return (false, 'Minimum order of ৳ 300 required for BAZAAR10.');
      }
      final discount = (state.subtotal * 0.10).clamp(0.0, 100.0);
      state = state.copyWith(
        appliedCoupon: cleanCode,
        couponDiscount: discount,
      );
      return (true, '10% discount (৳ ${discount.toStringAsFixed(0)}) applied!');
    } else if (cleanCode == 'FREEDELIVERY') {
      state = state.copyWith(
        appliedCoupon: cleanCode,
        couponDiscount: CartState.standardDeliveryFee,
      );
      return (true, 'Free delivery coupon applied!');
    }

    return (false, 'Invalid coupon code. Try "SHODAI50" or "BAZAAR10".');
  }

  /// Removes currently applied coupon.
  void removeCoupon() {
    state = state.copyWith(clearCoupon: true);
  }
}

/// Global provider for the shopping cart.
final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

/// Convenience provider returning the total count of items in cart
final cartItemsCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider.select((state) => state.totalItemsCount));
});
