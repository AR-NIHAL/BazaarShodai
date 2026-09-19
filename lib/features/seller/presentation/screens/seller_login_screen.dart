import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'seller_dashboard_screen.dart';
import 'seller_signup_screen.dart';

/// Screen allowing registered merchants to authenticate directly into the Vendor Portal.
class SellerLoginScreen extends ConsumerStatefulWidget {
  const SellerLoginScreen({super.key});

  @override
  ConsumerState<SellerLoginScreen> createState() => _SellerLoginScreenState();
}

class _SellerLoginScreenState extends ConsumerState<SellerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSellerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInSellerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome back to your Vendor Portal!'),
          backgroundColor: AppColors.secondaryDark,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SellerDashboardScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign in failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Portal'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Seller Icon
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      size: 42,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Merchant Sign In',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Access your BazaarShodai store dashboard, manage daily produce stocks, and process customer orders.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 32),

                // Vendor Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Vendor Account Email',
                    hintText: 'vendor@example.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter vendor email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Vendor Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter your password';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryDark,
                  ),
                  onPressed: _isLoading ? null : _handleSellerLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Sign In to Vendor Dashboard'),
                ),
                const SizedBox(height: 20),

                // Register Shop Option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Want to sell on BazaarShodai? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SellerSignupScreen()),
                        );
                      },
                      child: const Text(
                        'Register Shop',
                        style: TextStyle(
                          color: AppColors.secondaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Back to buyer storefront
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Buyer Storefront'),
                ),
                const SizedBox(height: 24),

                // Customer vs Vendor note
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: AppColors.secondaryDark),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Note: Customer accounts cannot log in here. If you already have a customer account, you can register your shop from your Profile settings in Buyer mode.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
