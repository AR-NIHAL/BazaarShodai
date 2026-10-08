import 'package:bazaar_shodai/core/theme/app_theme.dart';
import 'package:bazaar_shodai/features/auth/presentation/providers/auth_providers.dart';
import 'package:bazaar_shodai/features/buyer/domain/models/product_model.dart';
import 'package:bazaar_shodai/features/cart/domain/models/cart_item_model.dart';
import 'package:bazaar_shodai/features/cart/domain/models/cart_state.dart';
import 'package:bazaar_shodai/features/cart/presentation/providers/cart_providers.dart';
import 'package:bazaar_shodai/features/cart/presentation/screens/cart_screen.dart';
import 'package:flutter/material.dart';
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

  group('CartScreen UI Rendering with AppTheme', () {
    testWidgets('Renders all cart items, delivery bar, coupon section and order summary without layout errors',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(const AsyncData(null)),
        ],
      );
      addTearDown(container.dispose);

      const product1 = ProductModel(
        id: 'p_tomato',
        title: 'Fresh Tomato',
        description: 'Red ripe tomatoes',
        price: 45.0,
        originalPrice: 60.0,
        stock: 10,
        category: 'Vegetables',
        unit: '1 kg',
        imageUrls: ['https://example.com/tomato.png'],
        sellerId: 's_green',
        sellerName: 'green valley',
      );

      const product2 = ProductModel(
        id: 'p_veg',
        title: 'Mixed Vegetables',
        description: 'Assorted seasonal greens',
        price: 100.0,
        originalPrice: 110.0,
        stock: 50,
        category: 'Vegetables',
        unit: '1 kg',
        imageUrls: ['https://example.com/veg.png'],
        sellerId: 's_green',
        sellerName: 'green valley',
      );

      container.read(cartProvider.notifier).addItem(product1, quantity: 2);
      container.read(cartProvider.notifier).addItem(product2, quantity: 1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header
      expect(find.text('My Shopping Cart'), findsOneWidget);
      expect(find.text('3 items from 1 vendor'), findsOneWidget);

      // Verify both items rendered
      expect(find.text('Fresh Tomato'), findsOneWidget);
      expect(find.text('Mixed Vegetables'), findsOneWidget);

      // Verify coupon section and Apply button
      expect(find.text('Apply Promo Code / Coupon'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);

      // Scroll down to reveal order summary
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Verify order summary & payable amount
      expect(find.text('Order Bill Summary'), findsOneWidget);
      expect(find.text('Total Payable'), findsWidgets);
      expect(find.text('Proceed to Checkout'), findsOneWidget);
    });
  });
}

