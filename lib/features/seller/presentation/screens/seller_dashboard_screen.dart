import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../buyer/presentation/screens/main_nav_screen.dart';
import '../providers/seller_providers.dart';
import 'add_product_screen.dart';

/// Comprehensive dashboard shell for verified and pending vendors on BazaarShodai.
/// Provides dual-role switcher back to customer view, catalog management with Cloudinary uploads,
/// and live store performance tracking.
class SellerDashboardScreen extends ConsumerStatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  ConsumerState<SellerDashboardScreen> createState() =>
      _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends ConsumerState<SellerDashboardScreen> {
  int _currentIndex = 0;

  void _navigateToCustomerView() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
      );
    }
  }

  void _confirmDeleteProduct(String productId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to remove "$title" from your store?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(sellerRepositoryProvider).deleteProduct(productId);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product deleted successfully.'),
                    backgroundColor: AppColors.textPrimary,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(currentUserProfileStreamProvider);

    return userProfileAsync.when(
      data: (user) {
        final sellerId = user?.uid ?? '';
        final shopName = user?.shopDetails?.shopName.isNotEmpty == true
            ? user!.shopDetails!.shopName
            : 'My Vendor Shop';
        final isApproved = user?.isApproved ?? false;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.store, color: AppColors.secondaryDark, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Vendor Portal',
                        style: TextStyle(
                          fontSize: 12,
                          color: isApproved ? AppColors.primaryDark : AppColors.secondaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Dual-Role Switcher Chip: Switch back to Customer View
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ActionChip(
                  avatar: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Customer View',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  backgroundColor: AppColors.primarySurface,
                  side: BorderSide(color: AppColors.primaryLight.withValues(alpha: 0.5)),
                  onPressed: _navigateToCustomerView,
                ),
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildOverviewTab(shopName, isApproved, user?.name ?? '', sellerId),
              _buildProductsTab(sellerId),
              _buildOrdersTab(),
              _buildSettingsTab(user),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Overview',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'Products',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
              NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: 'Shop Settings',
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: Text('Error loading seller dashboard: $e'),
        ),
      ),
    );
  }

  // 1. Overview Tab
  Widget _buildOverviewTab(String shopName, bool isApproved, String ownerName, String sellerId) {
    final sellerProductsAsync = ref.watch(sellerProductsStreamProvider(sellerId));
    final activeItemsCount = sellerProductsAsync.value?.length ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Approval Status Banner
        if (!isApproved)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB), // Amber 50
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.secondary),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.pending_actions, color: AppColors.secondaryDark, size: 26),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shop Under Verification',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.secondaryDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your seller registration is currently under review by BazaarShodai admin. You can publish products in the meantime.',
                        style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified, color: AppColors.primaryDark, size: 24),
                SizedBox(width: 10),
                Text(
                  'Verified BazaarShodai Merchant',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

        // Welcome Merchant Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD97706), Color(0xFFB45309)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondaryDark.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $ownerName',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                shopName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Manage your grocery catalog, upload fresh produce via camera/gallery, and track store performance directly.',
                style: TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Metrics Grid
        const Text(
          'Store Performance',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard('Total Revenue', '৳ 0', Icons.payments_outlined, AppColors.primary),
            _buildStatCard('Total Orders', '0', Icons.shopping_bag_outlined, AppColors.info),
            _buildStatCard('Active Items', '$activeItemsCount', Icons.inventory_2_outlined, AppColors.secondary),
            _buildStatCard('Store Rating', '5.0 ★', Icons.star_outline, AppColors.warning),
          ],
        ),
        const SizedBox(height: 20),

        // Quick Action: Add Product
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddProductScreen()),
            );
          },
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add New Product to Shop'),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Icon(icon, size: 20, color: color),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // 2. Products Tab (Real Vendor Products from Firestore)
  Widget _buildProductsTab(String sellerId) {
    if (sellerId.isEmpty) {
      return const Center(child: Text('Vendor account details not loaded.'));
    }

    final productsAsync = ref.watch(sellerProductsStreamProvider(sellerId));

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 72, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Product Catalog is Empty',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add your farm-fresh vegetables, fish, spices, or grocery items to start selling directly to local customers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddProductScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Product'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Products (${products.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddProductScreen()),
                      );
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Product', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 65,
                            height: 65,
                            color: AppColors.surfaceVariant,
                            child: product.primaryImage.isNotEmpty
                                ? Image.network(
                                    product.primaryImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: AppColors.textMuted,
                                    ),
                                  )
                                : const Icon(
                                    Icons.shopping_bag_outlined,
                                    color: AppColors.textMuted,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '৳${product.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (product.hasDiscount) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '৳${product.originalPrice!.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Category: ${product.category} • Stock: ${product.stock}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                          tooltip: 'Delete Product',
                          onPressed: () {
                            _confirmDeleteProduct(product.id, product.title);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading products: $e')),
    );
  }

  // 3. Orders Tab
  Widget _buildOrdersTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 72, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text(
              'No Orders Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'When customers purchase products from your shop, order requests will appear here for packaging and dispatch.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Settings Tab
  Widget _buildSettingsTab(dynamic user) {
    final shop = user?.shopDetails;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Shop Details Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shop Profile Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),
              _buildDetailRow('Shop Name', shop?.shopName ?? 'N/A'),
              _buildDetailRow('Owner Name', user?.name ?? 'N/A'),
              _buildDetailRow('Email', user?.email ?? 'N/A'),
              _buildDetailRow('Business Phone', shop?.phone ?? 'N/A'),
              _buildDetailRow('Shop Address', shop?.address ?? 'N/A'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Dual-Role Switcher: Switch to Customer View
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.primaryLight),
          ),
          color: AppColors.primarySurface,
          child: ListTile(
            leading: const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryDark),
            title: const Text(
              'Switch to Customer View',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
            ),
            subtitle: const Text('Browse marketplace products as a buyer'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primaryDark),
            onTap: _navigateToCustomerView,
          ),
        ),
        const SizedBox(height: 16),

        // Sign Out
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.error),
          title: const Text('Sign Out from Vendor Portal', style: TextStyle(color: AppColors.error)),
          onTap: () async {
            final navigator = Navigator.of(context);
            await ref.read(authRepositoryProvider).signOut();
            if (!mounted) return;
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainNavScreen()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
