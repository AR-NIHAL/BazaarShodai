import 'package:bazaar_shodai/features/buyer/domain/models/product_model.dart';
import 'package:bazaar_shodai/features/buyer/presentation/screens/product_details_screen.dart';
import 'package:bazaar_shodai/features/cart/presentation/providers/cart_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sampleFishProduct = ProductModel(
    id: 'prod_hilsa_01',
    title: 'Fresh Padma River Hilsa',
    bengaliTitle: 'তাজা পদ্মা নদীর রূপালী ইলিশ',
    description: 'Caught fresh from Padma river with river cold-chain guarantee.',
    price: 1450,
    originalPrice: 1750,
    stock: 5,
    category: 'Fish & Meat',
    unit: '1 kg',
    imageUrls: ['assets/images/tomato_sample.jpg'],
    origin: 'Padma Direct · Chandpur Mohona Confluence',
    harvestTime: 'Harvested 4h ago',
    sellerId: 'seller_fisherman_01',
    sellerName: 'Rafiqul Islam',
  );

  const sampleVegProduct = ProductModel(
    id: 'prod_tomato_01',
    title: 'Native Organic Red Tomato',
    bengaliTitle: 'দেশি টাটকা লাল টমেটো',
    description: 'Organically grown red tomatoes direct from Bogura soil.',
    price: 65,
    originalPrice: 85,
    stock: 40,
    category: 'Vegetables',
    unit: '1 kg',
    imageUrls: ['assets/images/tomato_sample.jpg'],
    sellerId: 'seller_farmer_01',
    sellerName: 'Bogura Agro Farm',
  );

  testWidgets('ProductDetailsScreen renders titles, pricing, formalin guarantee, and fisherman profile for Fish & Meat',
      (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ProductDetailsScreen(product: sampleFishProduct),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Bengali Subtitle
    expect(find.text('Fresh Padma River Hilsa'), findsWidgets);
    expect(find.text('তাজা পদ্মা নদীর রূপালী ইলিশ'), findsOneWidget);

    // Verify Pricing & Discount
    expect(find.text('৳ 1,450'), findsWidgets);
    expect(find.text('৳ 1,750'), findsOneWidget);
    expect(find.text('Save ৳ 300'), findsOneWidget);

    // Verify Lab Test Guarantee & Zero-Formalin
    expect(find.text('Zero-Formalin Guarantee'), findsOneWidget);
    expect(find.text('0.00 ppm'), findsOneWidget);

    // Verify Meet Your Fisherman & Cold Chain
    expect(find.text('Meet Your Fisherman'), findsOneWidget);
    expect(find.text('Cold-Chain Journey of this Product'), findsOneWidget);

    // Verify Fish & Meat specific cut options
    expect(find.text('Custom Fish Cut (কাটা ও পরিষ্কার)'), findsOneWidget);
    expect(find.text('Curry Cut (মাছের টুকরো - Cleaned)'), findsOneWidget);

    // Verify Sticky Bottom Add to Cart Button
    expect(find.text('Add to Cart'), findsOneWidget);

    // Tap Add to Cart and verify item in Cart State
    await tester.tap(find.text('Add to Cart'));
    await tester.pump();

    final cartState = container.read(cartProvider);
    expect(cartState.items.containsKey(sampleFishProduct.id), isTrue);
    expect(cartState.items[sampleFishProduct.id]?.price, equals(1450.0));
  });

  testWidgets('ProductDetailsScreen adapts dynamically for Vegetables without fish cuts',
      (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ProductDetailsScreen(product: sampleVegProduct),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Veg titles
    expect(find.text('Native Organic Red Tomato'), findsWidgets);
    expect(find.text('দেশি টাটকা লাল টমেটো'), findsOneWidget);

    // Verify Package weight options exist
    expect(find.text('Select Package Weight'), findsOneWidget);
    expect(find.text('500 gm'), findsOneWidget);
    expect(find.text('1 kg'), findsWidgets);

    // Verify Fish Cut does NOT exist for vegetables
    expect(find.text('Custom Fish Cut (কাটা ও পরিষ্কার)'), findsNothing);

    // Verify Meet Your Local Farmer
    expect(find.text('Meet Your Local Farmer'), findsOneWidget);
  });
}
