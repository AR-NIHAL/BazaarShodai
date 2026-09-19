import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'seller_dashboard_screen.dart';

/// Screen allowing an existing authenticated customer to register shop details and upgrade to a vendor.
class BecomeSellerScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const BecomeSellerScreen({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<BecomeSellerScreen> createState() => _BecomeSellerScreenState();
}

class _BecomeSellerScreenState extends ConsumerState<BecomeSellerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _shopNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleUpgrade() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final shop = ShopDetails(
        shopName: _shopNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      await authRepo.upgradeToSeller(
        uid: widget.user.uid,
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
        SnackBar(content: Text('Upgrade failed: ${e.toString()}'), backgroundColor: AppColors.error),
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
        title: const Text('Register Shop Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
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
                  'Upgrade to Seller Account',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use your existing account (${widget.user.email}) to start selling on BazaarShodai.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),

                // Shop Name
                TextFormField(
                  controller: _shopNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Shop / Store Name',
                    hintText: 'e.g. Green Valley Agro',
                    prefixIcon: Icon(Icons.store_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your shop name';
                    if (val.trim().length < 3) return 'Shop name must be at least 3 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Business Phone
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
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Shop Physical Address
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Shop Location / Physical Address',
                    hintText: 'e.g. Plot 5, Dhanmondi Market, Dhaka',
                    prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter shop physical location';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryDark,
                  ),
                  onPressed: _isLoading ? null : _handleUpgrade,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Register Shop & Open Dashboard'),
                ),
                const SizedBox(height: 16),

                // Cancel
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel & Remain Customer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
