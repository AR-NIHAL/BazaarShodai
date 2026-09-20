import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../checkout/presentation/providers/checkout_providers.dart';
import '../../../order/presentation/screens/orders_screen.dart';
import '../../../seller/presentation/screens/become_seller_screen.dart';
import '../../../seller/presentation/screens/seller_dashboard_screen.dart';
import '../../../seller/presentation/screens/seller_login_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

/// Production Profile Screen matching the official visual reference.
/// Features:
/// - Header with 'My Profile' and settings gear icon
/// - User Info card with avatar, name, email, and 'Role: CUSTOMER' pill
/// - Warm peach 'Become a Seller' banner
/// - Menu list: Order History, Delivery Addresses, Saved Items, Help Center, About
/// - Red Logout action with confirmation
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _showHelpCenter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'BazaarShodai Help Center',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Need assistance with your grocery orders or vendor store?',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone, color: AppColors.primary),
                ),
                title: const Text('Customer Hotline: 09612-BAZAAR', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Toll-free daily 7 AM - 11 PM'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dialing Hotline: 09612-229227')),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF2563EB)),
                ),
                title: const Text('Live WhatsApp Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('+880 1712-345678'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Connecting to WhatsApp Care Desk...')),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDF2F8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.email_outlined, color: Color(0xFFDB2777)),
                ),
                title: const Text('Email Support', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('support@bazaarshodai.com'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Emailing support@bazaarshodai.com')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeliveryAddressesModal() {
    final addresses = ref.read(addressesProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Saved Delivery Addresses',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...addresses.map((addr) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFECFDF5),
                        child: Icon(
                          addr.label == 'Office' ? Icons.business : Icons.home,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${addr.label} (${addr.recipientName})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${addr.formattedAddress}\nPhone: ${addr.phoneNumber}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: addr.isDefault
                          ? const Chip(
                              label: Text('Default', style: TextStyle(fontSize: 10, color: AppColors.primary)),
                              backgroundColor: Color(0xFFD1FAE5),
                              padding: EdgeInsets.zero,
                            )
                          : null,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.eco_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('About BazaarShodai'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BazaarShodai is a multi-vendor direct farm-to-doorstep grocery marketplace in Bangladesh.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'Tagline: Fresh from Local, For a Better Tomorrow',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
            ),
            SizedBox(height: 8),
            Text('Version: 1.0.0+1 (Production Release)'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to sign out of BazaarShodai?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authRepositoryProvider).signOut();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed out successfully.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateChangesProvider).value;
    final userProfileAsync = ref.watch(currentUserProfileStreamProvider);
    final user = userProfileAsync.asData?.value;

    final displayName = user?.name.isNotEmpty == true
        ? user!.name
        : (authUser?.displayName?.isNotEmpty == true ? authUser!.displayName! : (authUser != null ? 'Customer' : 'Guest Shopper'));
    final email = user?.email.isNotEmpty == true
        ? user!.email
        : (authUser?.email ?? 'Sign in to access account');
    final role = user?.role.name ?? 'customer';
    final isSeller = user?.role == UserRole.seller;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF0F172A)),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF0F172A), size: 24),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. User Info Header
          InkWell(
            onTap: () {
              if (authUser == null) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  // User Avatar
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSeller
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFD1FAE5),
                      border: Border.all(
                        color: isSeller ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isSeller ? const Color(0xFFB45309) : const Color(0xFF047857),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name, Email, Role pill
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSeller ? const Color(0xFFFEF3C7) : const Color(0xFFE6F8F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Role: ${role.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSeller ? const Color(0xFFB45309) : const Color(0xFF047857),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. 'Become a Seller' Card (Reference Design)
          _buildBecomeSellerBanner(authUser, user, isSeller),
          const SizedBox(height: 20),

          // 3. Menu List Items
          _buildMenuTile(
            icon: Icons.receipt_long_outlined,
            title: 'Order History',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              );
            },
          ),
          _buildMenuDivider(),

          _buildMenuTile(
            icon: Icons.location_on_outlined,
            title: 'Delivery Addresses',
            onTap: _showDeliveryAddressesModal,
          ),
          _buildMenuDivider(),

          _buildMenuTile(
            icon: Icons.favorite_border_rounded,
            title: 'Saved Items',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wishlist feature: You can bookmark items on the storefront!')),
              );
            },
          ),
          _buildMenuDivider(),

          _buildMenuTile(
            icon: Icons.help_outline_rounded,
            title: 'Help Center',
            onTap: _showHelpCenter,
          ),
          _buildMenuDivider(),

          _buildMenuTile(
            icon: Icons.info_outline_rounded,
            title: 'About BazaarShodai',
            onTap: _showAboutDialog,
          ),
          _buildMenuDivider(),

          const SizedBox(height: 24),

          // 4. Logout / Sign In Action
          if (authUser != null) ...[
            InkWell(
              onTap: _handleLogout,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 22),
                    SizedBox(width: 14),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.login_rounded),
              label: const Text('Sign In / Register as Customer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBecomeSellerBanner(dynamic authUser, UserModel? user, bool isSeller) {
    if (isSeller) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SellerDashboardScreen()),
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Color(0xFFB45309), size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.shopDetails?.shopName ?? 'My Vendor Store',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF78350F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Open Vendor Dashboard & Manage Store',
                          style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFB45309)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (authUser == null) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SellerLoginScreen()),
              );
            } else if (user != null) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BecomeSellerScreen(user: user)),
              );
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Stall / Storefront Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Color(0xFFC2410C), size: 30),
                ),
                const SizedBox(width: 16),

                // Title & Subtitle
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Become a Seller',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF78350F),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Sell your fresh goods on BazaarShodai',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9A3412),
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFFC2410C),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, color: const Color(0xFF1E293B), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Color(0xFF94A3B8),
      ),
      onTap: onTap,
    );
  }

  Widget _buildMenuDivider() {
    return const Divider(
      height: 1,
      thickness: 0.8,
      color: Color(0xFFF1F5F9),
      indent: 52,
    );
  }
}
