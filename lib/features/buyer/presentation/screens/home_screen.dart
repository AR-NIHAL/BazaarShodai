import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../seller/presentation/screens/add_product_screen.dart';
import '../providers/buyer_providers.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/category_selector.dart';
import '../widgets/product_card.dart';
import 'profile_screen.dart';

/// Production Home Screen for BazaarShodai buyers matching the official reference mockup.
/// Features:
/// - Brand logo with subtitle
/// - Notification bell with active badge
/// - Delivery location indicator
/// - Rounded search bar + separate filter button (tune)
/// - Promotional hero banner with 'Shop Now →' CTA
/// - Circular pastel category selector
/// - 'Popular Near You' section with 'See All >'
/// - Real-time 2-column product grid with zero hardcoded dummy data
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final authUser = ref.watch(authStateChangesProvider).value;
    final userProfileAsync = ref.watch(currentUserProfileStreamProvider);
    final user = userProfileAsync.asData?.value;
    final displayName = user?.name.isNotEmpty == true
        ? user!.name
        : (authUser?.displayName?.isNotEmpty == true ? authUser!.displayName! : '');

    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFA),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(productsStreamProvider);
            ref.invalidate(categoriesStreamProvider);
          },
          child: CustomScrollView(
            slivers: [
              // 1. Top Bar: Logo & Notification Bell
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Brand Logo
                      Image.asset(
                        'assets/images/logo.png',
                        height: 42,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.eco_rounded,
                                color: Color(0xFF047857),
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Bazaar',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF047857),
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Shodai',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0F172A),
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Fresh from Local, For a Better Tomorrow',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Profile Avatar / Icon (Whoever joins, their profile is shown)
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: authUser != null
                                    ? const Color(0xFFD1FAE5)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: authUser != null
                                      ? AppColors.primary
                                      : const Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: authUser != null
                                    ? Text(
                                        displayName.isNotEmpty
                                            ? displayName[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: Color(0xFF047857),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person_outline,
                                        color: Color(0xFF0F172A),
                                        size: 22,
                                      ),
                              ),
                            ),
                            if (authUser != null)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 11,
                                  height: 11,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
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

              // 2. Delivery Location Indicator
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF059669),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Delivering to: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        'Dhaka, Bangladesh',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Color(0xFF0F172A),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Search Bar & Filter Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: Row(
                    children: [
                      // Search Input
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              ref.read(searchQueryProvider.notifier).setQuery(val);
                            },
                            decoration: InputDecoration(
                              hintText: 'Search farm-fresh produce, fish, spices...',
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xFF64748B),
                                size: 22,
                              ),
                              suffixIcon: searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref.read(searchQueryProvider.notifier).clear();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Filter Button (Tune)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF0F172A),
                            size: 20,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sort & filter filters ready in next module!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Hero Promotional Banner (Only show when not actively searching)
              if (searchQuery.isEmpty) ...[
                const SliverToBoxAdapter(child: BannerCarousel()),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),

                // 5. Circular Pastel Category Selector
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                const SliverToBoxAdapter(child: CategorySelector()),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],

              // 6. Section Header: "Popular Near You" & "See All >"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        searchQuery.isNotEmpty
                            ? 'Search Results ("$searchQuery")'
                            : (selectedCategory ?? 'Popular Near You'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              ref.read(selectedCategoryProvider.notifier).selectCategory('All');
                            },
                            child: const Row(
                              children: [
                                Text(
                                  'See All',
                                  style: TextStyle(
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: Color(0xFF059669),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 7. Products 2-Column Grid (Zero fake data, strictly real-time from Firestore)
              productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    final currentUser = ref.watch(currentUserProfileStreamProvider).value;
                    final isSeller = currentUser?.role == UserRole.seller;

                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                searchQuery.isNotEmpty
                                    ? Icons.search_off_rounded
                                    : Icons.storefront_outlined,
                                size: 40,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isNotEmpty
                                  ? 'No Matching Products'
                                  : (selectedCategory != null
                                      ? 'No $selectedCategory Found'
                                      : 'No Products Listed Yet'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              searchQuery.isNotEmpty
                                  ? 'No items matched "$searchQuery". Try different keywords or clear filters.'
                                  : (selectedCategory != null
                                      ? 'There are currently no items published under $selectedCategory.'
                                      : 'Merchants have not published any grocery items yet. As soon as a vendor uploads farm-fresh produce, it will appear here in real time.'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (searchQuery.isNotEmpty || selectedCategory != null)
                              OutlinedButton(
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(searchQueryProvider.notifier).clear();
                                  ref.read(selectedCategoryProvider.notifier).selectCategory('All');
                                },
                                child: const Text('Reset All Filters'),
                              )
                            else if (isSeller)
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const AddProductScreen()),
                                  );
                                },
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('Publish Your First Product'),
                              )
                            else
                              OutlinedButton.icon(
                                onPressed: () => ref.invalidate(productsStreamProvider),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh Marketplace'),
                              ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];
                          return ProductCard(
                            product: product,
                            onTap: () {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${product.title} selected'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          );
                        },
                        childCount: products.length,
                      ),
                    ),
                  );
                },
                loading: () => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 130,
                              color: const Color(0xFFF1F5F9),
                            ),
                            const Expanded(
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      childCount: 4,
                    ),
                  ),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, size: 40, color: AppColors.error),
                          const SizedBox(height: 8),
                          Text('Failed to load products: $err'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(productsStreamProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
