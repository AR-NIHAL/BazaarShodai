import 'package:bazaar_shodai/features/buyer/domain/models/product_model.dart';
import 'package:bazaar_shodai/features/cart/domain/models/cart_item_model.dart';
import 'package:bazaar_shodai/features/cart/domain/models/cart_state.dart';
import 'package:bazaar_shodai/features/cart/presentation/providers/cart_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CartItemModel Domain Logic', () {
    test('Calculates line totals, discounts and savings correctly', () {
      const item = CartItemModel(
        productId: 'p1',
        title: 'Bogra Cauliflower',
        image: 'https://example.com/cauliflower.jpg',
        price: 40.0,
        originalPrice: 50.0,
        quantity: 3,
        unit: '1 pc',
        sellerId: 's1',
        sellerName: 'Bogra Fresh Mart',
        stock: 10,
      );

      expect(item.totalPrice, equals(120.0));
      expect(item.totalOriginalPrice, equals(150.0));
      expect(item.savings, equals(30.0));
      expect(item.hasDiscount, isTrue);

      final map = item.toMap();
      final fromMap = CartItemModel.fromMap(map);
      expect(fromMap.productId, equals('p1'));
      expect(fromMap.totalPrice, equals(120.0));
    });
  });

  group('CartState Calculations', () {
    test('Correctly computes subtotal, free delivery threshold, and payable amount', () {
      const item1 = CartItemModel(
        productId: 'p1',
        title: 'Item 1',
        image: '',
        price: 200.0,
        originalPrice: 250.0,
        quantity: 2, // 400
        sellerId: 's1',
        sellerName: 'Vendor 1',
        stock: 5,
      );

      const item2 = CartItemModel(
        productId: 'p2',
        title: 'Item 2',
        image: '',
        price: 300.0,
        quantity: 1, // 300
        sellerId: 's2',
        sellerName: 'Vendor 2',
        stock: 5,
      );

      // Subtotal: 700 -> Below 1000, so delivery fee = 50
      final state = CartState(items: {'p1': item1, 'p2': item2});

      expect(state.totalItemsCount, equals(3));
      expect(state.subtotal, equals(700.0));
      expect(state.deliveryFee, equals(50.0));
      expect(state.hasFreeDelivery, isFalse);
      expect(state.amountNeededForFreeDelivery, equals(300.0));
      expect(state.totalPayable, equals(750.0));
      expect(state.uniqueSellers, containsAll(['Vendor 1', 'Vendor 2']));

      // With enough items to exceed 1000 Taka -> Delivery becomes FREE
      final item3 = item2.copyWith(quantity: 3); // 300 * 3 = 900
      final highState = CartState(items: {'p1': item1, 'p2': item3}); // 400 + 900 = 1300
      expect(highState.subtotal, equals(1300.0));
      expect(highState.deliveryFee, equals(0.0));
      expect(highState.hasFreeDelivery, isTrue);
      expect(highState.totalPayable, equals(1300.0));
    });
  });

  group('CartNotifier Riverpod Integration', () {
    test('Adds item, enforces stock limits, and manages quantity updates', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);

      final product = ProductModel(
        id: 'p100',
        title: 'Fresh Mango',
        description: 'Sweet Rajshahi mangoes',
        price: 150.0,
        originalPrice: 180.0,
        stock: 3,
        category: 'Fruits',
        imageUrls: const ['https://example.com/mango.jpg'],
        sellerId: 's10',
        sellerName: 'Rajshahi Orchards',
      );

      // 1. Add item
      final (success1, _) = notifier.addItem(product, quantity: 1);
      expect(success1, isTrue);
      expect(container.read(cartProvider).totalItemsCount, equals(1));
      expect(container.read(cartItemsCountProvider), equals(1));

      // 2. Increment up to stock limit
      final (success2, _) = notifier.increment('p100');
      expect(success2, isTrue);
      expect(container.read(cartProvider).items['p100']?.quantity, equals(2));

      notifier.increment('p100'); // qty = 3 (stock limit)
      expect(container.read(cartProvider).items['p100']?.quantity, equals(3));

      // Attempting to exceed stock should fail
      final (successExceed, errorMsg) = notifier.increment('p100');
      expect(successExceed, isFalse);
      expect(errorMsg, contains('Maximum stock limit reached'));
      expect(container.read(cartProvider).items['p100']?.quantity, equals(3));

      // 3. Decrement
      notifier.decrement('p100');
      expect(container.read(cartProvider).items['p100']?.quantity, equals(2));

      // 4. Coupons
      // Subtotal = 2 * 150 = 300
      final (couponRes, _) = notifier.applyCoupon('BAZAAR10');
      expect(couponRes, isTrue);
      expect(container.read(cartProvider).couponDiscount, equals(30.0)); // 10% of 300

      // 5. Clear cart
      notifier.clearCart();
      expect(container.read(cartProvider).isEmpty, isTrue);
      expect(container.read(cartItemsCountProvider), equals(0));
    });
  });
}
