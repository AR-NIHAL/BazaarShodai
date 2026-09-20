import 'package:bazaar_shodai/features/buyer/domain/models/product_model.dart';
import 'package:bazaar_shodai/features/buyer/presentation/widgets/product_card.dart';
import 'package:bazaar_shodai/features/cart/presentation/providers/cart_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  testWidgets('ProductCard displays title, discount badge, red price, seller name and + Add button without blank space',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 260,
              child: ProductCard(product: sampleProduct),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify Title
    expect(find.text('Local Tomato (Deshi)'), findsOneWidget);

    // Verify Discount Badge
    expect(find.text('-20%'), findsOneWidget);

    // Verify Seller Name
    expect(find.text('Green Valley Farm'), findsOneWidget);

    // Verify Price elements
    expect(find.text('80'), findsOneWidget);
    expect(find.text('৳ 100'), findsOneWidget);

    // Verify Add Button
    expect(find.text('Add'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);

    // Verify Wishlist Icon
    expect(find.byIcon(Icons.favorite_outline_rounded), findsOneWidget);

    // Verify Verified Checkmark
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('Tapping Add button adds item to cart and displays stepper',
      (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 260,
              child: ProductCard(product: sampleProduct),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify initially Add button is present
    expect(find.text('Add'), findsOneWidget);

    // Tap Add button
    await tester.tap(find.text('Add'));
    await tester.pump();

    // Verify Cart state updated
    final cartState = container.read(cartProvider);
    expect(cartState.items.containsKey(sampleProduct.id), isTrue);
    expect(cartState.items[sampleProduct.id]?.quantity, equals(1));

    // Verify Stepper is displayed
    expect(find.text('1'), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
