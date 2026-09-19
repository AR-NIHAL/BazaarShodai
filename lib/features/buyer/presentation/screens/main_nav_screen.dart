import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../seller/presentation/screens/become_seller_screen.dart';
import '../../../seller/presentation/screens/seller_dashboard_screen.dart';
import '../../../seller/presentation/screens/seller_login_screen.dart';

import 'home_screen.dart';

/// Main navigation shell for BazaarShodai.
/// Displays Home, Categories, Cart, Wishlist, and Profile tabs.
class MainNavScreen extends ConsumerStatefulWidget {
  const MainNavScreen({super.key});

  @override
  ConsumerState<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends ConsumerState<MainNavScreen> {
  int _currentIndex = 0;

  String _getAppBarTitle(int index) {
    switch (index) {
      case 1:
        return 'Categories';
      case 2:
        return 'My Cart';
      case 3:
        return 'My Orders';
      case 4:
        return 'Profile';
      default:
        return 'BazaarShodai';
    }
  }

  /// Gate helper: intercepts protected actions.
  /// If the user is unauthenticated, redirects them to [LoginScreen].
  /// Otherwise, executes [onAuthorized].
  void _requireAuthAction({required VoidCallback onAuthorized}) {
    final authUser = ref.read(authStateChangesProvider).value;
    if (authUser == null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      ).then((_) {
        if (ref.read(authStateChangesProvider).value != null) {
          onAuthorized();
        }
      });
    } else {
      onAuthorized();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
          ? null
          : AppBar(
              title: Text(_getAppBarTitle(_currentIndex)),
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          _buildCategoriesTab(),
          _buildCartTab(),
          _buildOrdersTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // 2. Categories Tab
  Widget _buildCategoriesTab() {
    return const Center(
      child: Text(
        'Categories Screen',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // 3. Cart Tab
  Widget _buildCartTab() {
    return const Center(
      child: Text(
        'Cart Screen',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // 4. Orders Tab
  Widget _buildOrdersTab() {
    return const Center(
      child: Text(
        'Orders Screen',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // 5. Profile Tab
  Widget _buildProfileTab() {
    final authUser = ref.watch(authStateChangesProvider).value;
    final userProfileAsync = ref.watch(currentUserProfileStreamProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // User Info Header or Guest Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: authUser == null
              ? Column(
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.surfaceVariant,
                      child: Icon(Icons.person_outline, size: 40, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Browsing as Guest',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sign in or create an account to view orders, save addresses, or apply as a vendor.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _requireAuthAction(
                        onAuthorized: () {},
                      ),
                      child: const Text('Sign In / Register as Customer'),
                    ),
                  ],
                )
              : userProfileAsync.when(
                  data: (user) {
                    final displayName = user?.name.isNotEmpty == true
                        ? user!.name
                        : (authUser.displayName ?? 'Customer');
                    final email = user?.email.isNotEmpty == true
                        ? user!.email
                        : (authUser.email ?? '');
                    final role = user?.role.name ?? 'customer';
                    final isSeller = user?.role == UserRole.seller;

                    return Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: isSeller
                              ? AppColors.secondaryLight.withValues(alpha: 0.5)
                              : AppColors.primarySurface,
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isSeller ? AppColors.secondaryDark : AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          displayName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(
                            'Role: ${role.toUpperCase()}',
                            style: TextStyle(
                              color: isSeller ? AppColors.secondaryDark : AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: isSeller
                              ? const Color(0xFFFFFBEB)
                              : AppColors.primarySurface,
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Column(
                    children: [
                      Text(authUser.email ?? 'Authenticated'),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 20),

        // Multi-Vendor Seller Portal Gate Card
        _buildSellerGateCard(authUser, userProfileAsync.asData?.value),
        const SizedBox(height: 16),

        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Help & Customer Support'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.policy_outlined),
          title: const Text('Terms & Privacy Policy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        if (authUser != null)
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed out successfully.')),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSellerGateCard(dynamic authUser, UserModel? user) {
    final bool isSeller = user?.role == UserRole.seller;

    if (isSeller) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.secondaryDark),
        ),
        color: const Color(0xFFFFFBEB),
        child: ListTile(
          leading: const Icon(Icons.store, color: AppColors.secondaryDark, size: 28),
          title: Text(
            user?.shopDetails?.shopName ?? 'My Vendor Store',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.secondaryDark),
          ),
          subtitle: const Text('Open Vendor Dashboard & Manage Store'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.secondaryDark),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SellerDashboardScreen()),
            );
          },
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.secondaryLight),
      ),
      color: const Color(0xFFFFFBEB),
      child: ListTile(
        leading: const Icon(Icons.store, color: AppColors.secondaryDark),
        title: const Text('Become a Seller / Vendor Portal', style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: const Text('Sell your fresh goods on BazaarShodai'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.secondaryDark),
        onTap: () {
          if (authUser == null) {
            // Guest -> open SellerLoginScreen
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SellerLoginScreen()),
            );
          } else if (user != null) {
            // Existing Customer -> open BecomeSellerScreen
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BecomeSellerScreen(user: user)),
            );
          }
        },
      ),
    );
  }
}
