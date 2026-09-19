import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/presentation/screens/signup_screen.dart';

/// An elegant modal bottom sheet prompting unauthenticated guests to sign in or register
/// when attempting protected actions like adding to cart, saving to wishlist, or checking out.
class AuthPromptSheet extends StatelessWidget {
  final String title;
  final String message;

  const AuthPromptSheet({
    super.key,
    this.title = 'Sign In to Continue',
    this.message =
        'Create a free account or sign in to save items to your wishlist, place grocery orders, and enjoy direct doorstep delivery.',
  });

  /// Convenient helper to display the modal bottom sheet from any widget context.
  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? message,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AuthPromptSheet(
        title: title ?? 'Sign In to Continue',
        message: message ??
            'Create a free account or sign in to save items to your wishlist, place grocery orders, and enjoy direct doorstep delivery.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Icon Badge
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.lock_open_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Features Checklist
            _buildBenefitRow(Icons.check_circle_outline, 'Save your weekly grocery cart & wishlist'),
            const SizedBox(height: 8),
            _buildBenefitRow(Icons.check_circle_outline, 'Fast doorstep delivery with live updates'),
            const SizedBox(height: 8),
            _buildBenefitRow(Icons.check_circle_outline, 'Exclusive discounts from local farmers & sellers'),
            const SizedBox(height: 24),

            // Primary Action: Sign In
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Sign In to My Account'),
            ),
            const SizedBox(height: 10),

            // Secondary Action: Sign Up
            OutlinedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                );
              },
              child: const Text('Create New Account'),
            ),
            const SizedBox(height: 12),

            // Continue browsing
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Continue Browsing as Guest',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
