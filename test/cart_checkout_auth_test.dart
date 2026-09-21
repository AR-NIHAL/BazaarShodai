import 'package:bazaar_shodai/features/auth/presentation/providers/auth_providers.dart';
import 'package:bazaar_shodai/features/buyer/domain/models/product_model.dart';
import 'package:bazaar_shodai/features/buyer/presentation/widgets/auth_prompt_sheet.dart';
import 'package:bazaar_shodai/features/cart/presentation/providers/cart_providers.dart';
import 'package:bazaar_shodai/features/cart/presentation/screens/cart_screen.dart';
import 'package:bazaar_shodai/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeUser extends Fake implements User {
  @override
  final String uid;
  @override
  final String email;

  FakeUser({required this.uid, required this.email});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const sampleProduct = ProductModel(
    id: 'prod_tomato_01',
    title: 'Local Tomato (Deshi)',
    description: 'Fresh farm-picked local organic red tomatoes.',
    price: 80,
    originalPrice: 100,
    stock: 25,
    category: 'Vegetables',
    unit: '1 kg',
    imageUrls: ['assets/images/tomato_sample.jpg'],
    sellerId: 'seller_gvf_01',
    sellerName: 'Green Valley Farm',
  );

  testWidgets(
      'Unauthenticated guest clicking Proceed to Checkout opens AuthPromptSheet, prevents CheckoutScreen, and preserves cart items on dismiss',
      (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWithValue(const AsyncData(null)),
      ],
    );
    addTearDown(container.dispose);

    // 1. Guest adds item to cart without signing in
    container.read(cartProvider.notifier).addItem(sampleProduct, quantity: 2);
    expect(container.read(cartProvider).totalItemsCount, equals(2));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: CartScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify product is listed in the cart
    expect(find.text('Local Tomato (Deshi)'), findsOneWidget);
    expect(find.text('Proceed to Checkout'), findsOneWidget);

    // 2. Tap Proceed to Checkout
    await tester.tap(find.text('Proceed to Checkout'));
    await tester.pumpAndSettle();

    // Verify AuthPromptSheet is presented with clear sign-in and sign-up options
    expect(find.byType(AuthPromptSheet), findsOneWidget);
    expect(find.text('Sign In to Checkout'), findsOneWidget);
    expect(find.text('Sign In to My Account'), findsOneWidget);
    expect(find.text('Create New Account'), findsOneWidget);

    // Verify CheckoutScreen is NOT shown
    expect(find.byType(CheckoutScreen), findsNothing);

    // 3. User chooses to continue browsing as guest
    await tester.tap(find.text('Continue Browsing as Guest'));
    await tester.pumpAndSettle();

    // Sheet is dismissed, user is back on CartScreen with cart intact
    expect(find.byType(AuthPromptSheet), findsNothing);
    expect(find.byType(CartScreen), findsOneWidget);
    expect(find.text('Local Tomato (Deshi)'), findsOneWidget);
    expect(container.read(cartProvider).totalItemsCount, equals(2));
  });

  testWidgets(
      'Authenticated buyer clicking Proceed to Checkout navigates directly to CheckoutScreen without AuthPromptSheet',
      (WidgetTester tester) async {
    final fakeUser = FakeUser(uid: 'buyer_real_uid_777', email: 'buyer@bazaarshodai.com');

    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWithValue(AsyncData(fakeUser)),
      ],
    );
    addTearDown(container.dispose);

    // Pre-populate cart items
    container.read(cartProvider.notifier).addItem(sampleProduct, quantity: 1);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: CartScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Proceed to Checkout
    await tester.tap(find.text('Proceed to Checkout'));
    await tester.pumpAndSettle();

    // AuthPromptSheet should NOT be shown
    expect(find.byType(AuthPromptSheet), findsNothing);

    // CheckoutScreen should be opened
    expect(find.byType(CheckoutScreen), findsOneWidget);

    // Cart items are preserved
    expect(container.read(cartProvider).totalItemsCount, equals(1));
  });

  test('Cart items remain preserved across authentication status transitions', () {
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWithValue(const AsyncData(null)),
      ],
    );
    addTearDown(container.dispose);

    // Step 1: Unauthenticated user adds items
    container.read(cartProvider.notifier).addItem(sampleProduct, quantity: 3);
    expect(container.read(cartProvider).totalItemsCount, equals(3));
    expect(container.read(cartProvider).items.containsKey('prod_tomato_01'), isTrue);

    // Step 2: Simulate user sign-in transition
    final fakeUser = FakeUser(uid: 'user_456', email: 'user@example.com');
    container.updateOverrides([
      authStateChangesProvider.overrideWithValue(AsyncData(fakeUser)),
    ]);

    // Cart items must remain completely intact
    expect(container.read(cartProvider).totalItemsCount, equals(3));
    expect(container.read(cartProvider).items['prod_tomato_01']!.quantity, equals(3));
    expect(container.read(authStateChangesProvider).value?.uid, equals('user_456'));
  });
}
