import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../order/presentation/screens/orders_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import 'home_screen.dart';

/// Main navigation shell for BazaarShodai.
/// Displays 4 primary tabs: Home, Cart, Orders, and Settings.
class MainNavScreen extends ConsumerStatefulWidget {
  const MainNavScreen({super.key});

  @override
  ConsumerState<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends ConsumerState<MainNavScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartItemsCountProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
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
}
