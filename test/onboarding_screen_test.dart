import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bazaar_shodai/features/auth/presentation/screens/onboarding_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('OnboardingScreen renders slides, titles, badges and action buttons', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );

    // Initial slide (Shopper)
    expect(find.text('BazaarShodai'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('100% Organic & Fresh'), findsOneWidget);
    expect(find.text('Farm-Fresh Groceries at Your Door'), findsOneWidget);
    expect(find.text('Pesticide-Free'), findsNothing);
    expect(find.text('Explore as Guest'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Tap Next to Slide 2 (Seller)
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Multi-Vendor Marketplace'), findsOneWidget);
    expect(find.text('Empowering Local Farmers & Sellers'), findsOneWidget);
    expect(find.text('2-Min Shop Setup'), findsNothing);

    // Tap Next to Slide 3 (Delivery & Final Actions)
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Fast & Reliable Delivery'), findsOneWidget);
    expect(find.text('Fair Prices & Fast Doorstep Delivery'), findsOneWidget);
    expect(find.text('Real-Time Tracking'), findsNothing);
    expect(find.text('Start Shopping as Guest'), findsOneWidget);
    expect(find.text('Are you a seller? Sign In / Join Here'), findsOneWidget);
  });
}
