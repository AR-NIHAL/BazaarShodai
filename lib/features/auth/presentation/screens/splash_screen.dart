import 'package:flutter/material.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../buyer/presentation/screens/main_nav_screen.dart';
import 'onboarding_screen.dart';

/// App Splash Screen that handles initial entry routing.
/// Enforces a 2-second delay and inspects the onboarding completion state in LocalStorage.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleInitialRouting();
  }

  Future<void> _handleInitialRouting() async {
    // 1. Mandatory 2-second delay for branding and initialization
    await Future.delayed(const Duration(seconds: 2));

    // 2. Read onboarding completion flag from local storage
    final bool isOnboardingCompleted = await LocalStorageService.isOnboardingCompleted();

    // 3. Ensure widget is still mounted before navigation
    if (!mounted) return;

    // 4. Route to MainNavScreen if onboarding completed, or OnboardingScreen otherwise
    if (isOnboardingCompleted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // App Logo / Emblem
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Brand Title
              const Text(
                'BazaarShodai',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Tagline
              const Text(
                'Fresh Groceries • Direct from Local Vendors',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),

              const Spacer(),

              // Loading Spinner & Region / Spark plan indicator
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
