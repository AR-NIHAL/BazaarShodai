import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../order/presentation/screens/orders_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

import 'home_screen.dart';

/// Main navigation shell for BazaarShodai.
/// Displays Home, Categories, Cart, Orders, and Settings tabs.
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
        return 'Settings';
      default:
        return 'BazaarShodai';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartItemsCountProvider);

    return Scaffold(
      appBar: (_currentIndex == 0 || _currentIndex == 2 || _currentIndex == 3 || _currentIndex == 4)
          ? null
          : AppBar(
              title: Text(_getAppBarTitle(_currentIndex)),
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          _buildCategoriesTab(),
          CartScreen(
            onExploreTap: () => setState(() => _currentIndex = 0),
          ),
          OrdersScreen(
            onExploreTap: () => setState(() => _currentIndex = 0),
          ),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: cartCount,
              isLabelVisible: cartCount > 0,
              backgroundColor: const Color(0xFF047857),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge.count(
              count: cartCount,
              isLabelVisible: cartCount > 0,
              backgroundColor: const Color(0xFF047857),
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
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



}
