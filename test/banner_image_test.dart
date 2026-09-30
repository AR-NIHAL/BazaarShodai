import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Verify all 3 banner images exist and can be loaded from rootBundle', () async {
    final images = [
      'assets/images/banner_mustard_oil.jpg',
      'assets/images/banner_padma_hilsa.jpg',
      'assets/images/banner_vegetables.jpg',
    ];

    for (final path in images) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: '$path should not be empty');
    }
  });
}
