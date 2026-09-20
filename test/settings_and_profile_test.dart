import 'package:bazaar_shodai/core/services/local_storage_service.dart';
import 'package:bazaar_shodai/core/theme/app_theme.dart';
import 'package:bazaar_shodai/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Dark Mode Persistence & ThemeModeNotifier Tests', () {
    test('LocalStorageService defaults to light and updates dark mode flag', () async {
      expect(await LocalStorageService.isDarkMode(), isFalse);

      await LocalStorageService.setDarkMode(true);
      expect(await LocalStorageService.isDarkMode(), isTrue);

      await LocalStorageService.setDarkMode(false);
      expect(await LocalStorageService.isDarkMode(), isFalse);
    });

    test('ThemeModeNotifier toggles ThemeMode and updates local storage', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Default state
      expect(container.read(themeModeProvider), equals(ThemeMode.light));

      // Toggle to dark
      await container.read(themeModeProvider.notifier).toggleDarkMode(true);
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
      expect(await LocalStorageService.isDarkMode(), isTrue);

      // Toggle back to light
      await container.read(themeModeProvider.notifier).toggleDarkMode(false);
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
      expect(await LocalStorageService.isDarkMode(), isFalse);
    });

    test('AppTheme darkTheme is properly configured with dark slate colors', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.brightness, equals(Brightness.dark));
      expect(darkTheme.scaffoldBackgroundColor, equals(const Color(0xFF0F172A)));
      expect(darkTheme.colorScheme.surface, equals(const Color(0xFF1E293B)));
    });
  });
}
