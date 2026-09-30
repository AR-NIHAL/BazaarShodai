import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bazaar_shodai/features/buyer/presentation/widgets/banner_carousel.dart';

void main() {
  testWidgets('BannerCarousel renders without overflow on various screen sizes', (tester) async {
    // Test on small screen (360x640)
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BannerCarousel(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(BannerCarousel), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'Should have no overflow or layout exceptions');
  });
}
