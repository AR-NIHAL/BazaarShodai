import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';

/// Notifier managing active [ThemeMode] (light or dark) with persistent local storage.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.light;
  }

  Future<void> _loadTheme() async {
    final isDark = await LocalStorageService.isDarkMode();
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Toggles between dark mode and light mode, persisting choice to local storage.
  Future<void> toggleDarkMode(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    await LocalStorageService.setDarkMode(isDark);
  }
}

/// Global provider for application ThemeMode.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
