import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'seller_dashboard_screen.dart';

/// Screen allowing new merchants to register a shop and create a vendor account.
class SellerSignupScreen extends ConsumerStatefulWidget {
  const SellerSignupScreen({super.key});

  @override
  ConsumerState<SellerSignupScreen> createState() => _SellerSignupScreenState();
}

class _SellerSignupScreenState extends ConsumerState<SellerSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Owner credentials
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Shop details
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final shop = ShopDetails(
        shopName: _shopNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      await authRepo.signUpSellerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        shopDetails: shop,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop registered successfully! Welcome to your Vendor Portal.'),
          backgroundColor: AppColors.primaryDark,
        ),
      );

      // Open Seller Dashboard directly
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SellerDashboardScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString()}'), backgroundColor: AppColors.error),
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
        title: const Text('Register Vendor Shop'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vendor Header Emblem
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.storefront,
                      size: 38,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Join BazaarShodai as a Seller',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Reach thousands of local buyers directly. Sell your farm-fresh produce and grocery items.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),

                // Section 1: Shop Details
                _buildSectionHeader('Shop Information', Icons.store),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _shopNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Shop / Business Name',
                    hintText: 'e.g. Deshi Agro Produce',
                    prefixIcon: Icon(Icons.store_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter your shop name';
                    if (val.trim().length < 3) return 'Shop name must be at least 3 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Business Contact Phone',
                    hintText: 'e.g. +8801700000000',
                    prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter business contact number';
                    if (val.trim().length < 6) return 'Enter a valid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Shop Address / Market Location',
                    hintText: 'e.g. Shop #12, Karwan Bazar, Dhaka',
                    prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter shop physical location';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Section 2: Owner Account
                _buildSectionHeader('Merchant Account Credentials', Icons.person),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Owner Full Name',
                    hintText: 'e.g. Karim Ullah',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter owner name';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Vendor Email Address',
                    hintText: 'e.g. vendor@example.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter vendor email';
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(val.trim())) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Minimum 6 characters',
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
                    if (val == null || val.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_reset_outlined, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (val) {
                    if (val != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Register Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryDark,
                  ),
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Complete Shop Registration'),
                ),
                const SizedBox(height: 16),

                // Already have a vendor account?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have a vendor account? ', style: TextStyle(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Sign In as Vendor',
                        style: TextStyle(color: AppColors.secondaryDark, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondaryDark),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
