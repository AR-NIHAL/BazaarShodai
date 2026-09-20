import 'package:shared_preferences/shared_preferences.dart';

/// Core service for managing persistent local key-value storage.
/// Encapsulates SharedPreferences operations to ensure type-safety and single source of truth.
class LocalStorageService {
  LocalStorageService._();

  // Storage Keys
  static const String _keyHasCompletedOnboarding = 'has_completed_onboarding';
  static const String _keyCartData = 'saved_cart_items_json';
  static const String _keyOrdersData = 'saved_orders_json';
  static const String _keyIsDarkMode = 'is_dark_mode';

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

  /// Saves the serialized cart JSON string to persistent storage.
  static Future<bool> saveCartJson(String jsonStr) async {
    final prefs = await _getPrefs();
    return await prefs.setString(_keyCartData, jsonStr);
  }

  /// Retrieves the serialized cart JSON string from storage.
  static Future<String?> getCartJson() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyCartData);
  }

  /// Clears persisted cart data.
  static Future<bool> clearCartData() async {
    final prefs = await _getPrefs();
    return await prefs.remove(_keyCartData);
  }

  /// Saves the serialized orders JSON string to persistent storage.
  static Future<bool> saveOrdersJson(String jsonStr) async {
    final prefs = await _getPrefs();
    return await prefs.setString(_keyOrdersData, jsonStr);
  }

  /// Retrieves the serialized orders JSON string from storage.
  static Future<String?> getOrdersJson() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyOrdersData);
  }

  /// Clears persisted orders data.
  static Future<bool> clearOrdersData() async {
    final prefs = await _getPrefs();
    return await prefs.remove(_keyOrdersData);
  }

  /// Checks whether Dark Mode is enabled by the user.
  static Future<bool> isDarkMode() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyIsDarkMode) ?? false;
  }

  /// Saves the user's Dark Mode preference.
  static Future<bool> setDarkMode(bool isDark) async {
    final prefs = await _getPrefs();
    return await prefs.setBool(_keyIsDarkMode, isDark);
  }

  /// Clears all key-value entries (useful for testing or full sign-out reset).
  static Future<bool> clearAll() async {
    final prefs = await _getPrefs();
    return await prefs.clear();
  }
}
