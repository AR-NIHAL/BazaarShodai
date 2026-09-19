import 'package:shared_preferences/shared_preferences.dart';

/// Core service for managing persistent local key-value storage.
/// Encapsulates SharedPreferences operations to ensure type-safety and single source of truth.
class LocalStorageService {
  LocalStorageService._();

  // Storage Keys
  static const String _keyHasCompletedOnboarding = 'has_completed_onboarding';

  /// Returns an instance of [SharedPreferences].
  static Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  /// Checks whether the user has completed the introductory onboarding flow.
  /// Defaults to `false` for first-time app launches.
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyHasCompletedOnboarding) ?? false;
  }

  /// Sets the onboarding completion status flag.
  static Future<bool> setOnboardingCompleted(bool value) async {
    final prefs = await _getPrefs();
    return await prefs.setBool(_keyHasCompletedOnboarding, value);
  }

  /// Clears all key-value entries (useful for testing or full sign-out reset).
  static Future<bool> clearAll() async {
    final prefs = await _getPrefs();
    return await prefs.clear();
  }
}
