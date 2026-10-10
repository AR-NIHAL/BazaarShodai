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
import 'product_details_screen.dart';
import 'profile_screen.dart';

/// Redesigned Home Screen for BazaarShodai matching the official reference screenshot.
/// Features:
/// - Brand logo with subtitle "📍 Dhanmondi, Dhaka ⌄"
/// - "Deliver to: Dhanmondi 27, Dhaka ⌄" with "⚡ Express 25m" pill badge
/// - Search input with search & mic icons + dark emerald tune filter button
/// - Promotional hero banner with small dot indicator inside bottom-right
/// - Horizontal category selector ("Categories" & "Explore All")
/// - "Today's Fresh Harvest" section with subtitle & "See All (48)"
/// - Interactive quick filter chips: "⚡ Flash Deals", "⭐ Top Rated", "🌱 100% Organic"
/// - Redesigned 2-column product grid with zero hardcoded dummy data
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _activeTagFilter; // 'flash_deals', 'top_rated', 'organic'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleTagFilter(String tag) {
    setState(() {
      if (_activeTagFilter == tag) {
        _activeTagFilter = null;
      } else {
        _activeTagFilter = tag;
      }
    });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFBFDFA),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(productsStreamProvider);
            ref.invalidate(categoriesStreamProvider);
          },
          child: CustomScrollView(
            slivers: [
              // 1. Top Bar: Brand Logo & Location Subtitle + Profile Avatar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Brand Logo & Subtitle Lockup
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.eco_rounded,
                                  color: Color(0xFF047857),
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'BazaarShodai',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : const Color(0xFF047857),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'বাজার সওদা',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: Color(0xFF059669),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Dhanmondi, Dhaka',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),

                      // User Profile Avatar with Online Dot
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
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: authUser != null
                                    ? const Color(0xFFD1FAE5)
                                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
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
                                          fontSize: 15,
                                          color: Color(0xFF047857),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person_outline,
                                        color: Color(0xFF0F172A),
                                        size: 20,
                                      ),
                              ),
                            ),
                            if (authUser != null)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
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

              // 2. Deliver To Row & Express 25m Badge
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Deliver To Location
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Delivery location: Dhanmondi 27, Dhaka'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.rotate(
                              angle: -0.4,
                              child: const Icon(
                                Icons.near_me_outlined,
                                color: Color(0xFF059669),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Deliver to: ',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Dhanmondi 27, Dhaka',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                            ),
                          ],
                        ),
                      ),

                      // Express 25m Pill Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: Color(0xFF047857),
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Express 25m',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Search Bar + Filter Tune Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
                  child: Row(
                    children: [
                      // Search Input with Search & Mic Icons
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
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
                              hintText: 'Search fresh harvest, Padma hilsa, spice...',
                              hintStyle: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF94A3B8),
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xFF64748B),
                                size: 20,
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (searchQuery.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.clear, size: 17, color: Color(0xFF94A3B8)),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref.read(searchQueryProvider.notifier).clear();
                                      },
                                    ),
                                  const Padding(
                                    padding: EdgeInsets.only(right: 10),
                                    child: Icon(
                                      Icons.mic_none_rounded,
                                      size: 19,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Dark Emerald Filter Button (Tune)
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFF047857),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF047857).withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sort & filter options active.'),
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

              // 4. Hero Promotional Banner (Hidden only when actively searching)
              if (searchQuery.isEmpty) ...[
                const SliverToBoxAdapter(child: BannerCarousel()),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),

                // 5. Circular Pastel Category Selector
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            ref.read(selectedCategoryProvider.notifier).selectCategory('All');
                          },
                          child: const Text(
                            'Explore All',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                const SliverToBoxAdapter(child: CategorySelector()),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],

              // 6. Section Header: "Today's Fresh Harvest" & Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                searchQuery.isNotEmpty
                                    ? 'Search Results ("$searchQuery")'
                                    : (selectedCategory ?? "Today's Fresh Harvest"),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                searchQuery.isNotEmpty
                                    ? 'Matching real-time items'
                                    : 'Harvested < 24h from Bogura & Jessore',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(selectedCategoryProvider.notifier).selectCategory('All');
                              setState(() => _activeTagFilter = null);
                            },
                            child: Row(
                              children: [
                                Text(
                                  productsAsync.asData != null
                                      ? 'See All (${productsAsync.asData!.value.length})'
                                      : 'See All',
                                  style: const TextStyle(
                                    color: Color(0xFF047857),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Quick Filter Chips Row (Flash Deals, Top Rated, 100% Organic)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: '⚡ Flash Deals',
                              isSelected: _activeTagFilter == 'flash_deals',
                              bgColor: const Color(0xFFFEF3C7),
                              textColor: const Color(0xFF92400E),
                              borderColor: const Color(0xFFFDE68A),
                              onTap: () => _toggleTagFilter('flash_deals'),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: '⭐ Top Rated',
                              isSelected: _activeTagFilter == 'top_rated',
                              bgColor: const Color(0xFFEFF6FF),
                              textColor: const Color(0xFF1E40AF),
                              borderColor: const Color(0xFFBFDBFE),
                              onTap: () => _toggleTagFilter('top_rated'),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: '🌱 100% Organic',
                              isSelected: _activeTagFilter == 'organic',
                              bgColor: const Color(0xFFECFDF5),
                              textColor: const Color(0xFF065F46),
                              borderColor: const Color(0xFFA7F3D0),
                              onTap: () => _toggleTagFilter('organic'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              // 7. Products 2-Column Grid (Zero fake data, strictly real-time from Firestore)
              productsAsync.when(
                data: (rawProducts) {
                  // Apply active tag filter
                  var products = rawProducts;
                  if (_activeTagFilter == 'flash_deals') {
                    products = products.where((p) => p.hasDiscount).toList();
                  } else if (_activeTagFilter == 'top_rated') {
                    products = products.where((p) => p.rating >= 4.5).toList();
                    if (products.isEmpty) {
                      products = rawProducts; // fallback if ratings not set
                    }
                  } else if (_activeTagFilter == 'organic') {
                    products = products.where((p) {
                      final lower = '${p.title} ${p.description} ${p.category}'.toLowerCase();
                      return lower.contains('organic') || lower.contains('veg');
                    }).toList();
                  }

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
                                searchQuery.isNotEmpty || _activeTagFilter != null
                                    ? Icons.search_off_rounded
                                    : Icons.storefront_outlined,
                                size: 40,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isNotEmpty || _activeTagFilter != null
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
                              searchQuery.isNotEmpty || _activeTagFilter != null
                                  ? 'No items matched your current filters. Try resetting filters.'
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
                            if (searchQuery.isNotEmpty || selectedCategory != null || _activeTagFilter != null)
                              OutlinedButton(
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(searchQueryProvider.notifier).clear();
                                  ref.read(selectedCategoryProvider.notifier).selectCategory('All');
                                  setState(() => _activeTagFilter = null);
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
                        childAspectRatio: 0.58,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];
                          return ProductCard(
                            product: product,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailsScreen(product: product),
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
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 130,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                              ),
                            ),
                            const Expanded(
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF047857),
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF047857) : bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF047857) : borderColor,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF047857).withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : textColor,
          ),
        ),
      ),
    );
  }
}
