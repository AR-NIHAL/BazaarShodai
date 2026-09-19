import 'package:flutter/material.dart';

/// App color palette for BazaarShodai.
/// Tailored for a fresh, authentic, and modern South Asian grocery & multi-vendor market experience.
class AppColors {
  AppColors._();

  // Primary Brand Colors (Fresh Emerald)
  static const Color primary = Color(0xFF059669); // Emerald 600
  static const Color primaryDark = Color(0xFF047857); // Emerald 700
  static const Color primaryLight = Color(0xFF34D399); // Emerald 400
  static const Color primarySurface = Color(0xFFECFDF5); // Emerald 50

  // Secondary Accent Colors (Warm Spice & Gold)
  static const Color secondary = Color(0xFFF59E0B); // Amber 500
  static const Color secondaryDark = Color(0xFFD97706); // Amber 600
  static const Color secondaryLight = Color(0xFFFDE68A); // Amber 200

  // Neutral Backgrounds & Surfaces
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate 100
  static const Color border = Color(0xFFE2E8F0); // Slate 200

  // Typography Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Status & Feedback Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
}
