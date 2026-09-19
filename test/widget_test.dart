import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bazaar_shodai/core/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalStorageService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isOnboardingCompleted returns false initially', () async {
      final isCompleted = await LocalStorageService.isOnboardingCompleted();
      expect(isCompleted, isFalse);
    });

    test('setOnboardingCompleted updates flag to true', () async {
      await LocalStorageService.setOnboardingCompleted(true);
      final isCompleted = await LocalStorageService.isOnboardingCompleted();
      expect(isCompleted, isTrue);
    });
  });
}
