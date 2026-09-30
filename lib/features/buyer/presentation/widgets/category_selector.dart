import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/category_model.dart';
import '../providers/buyer_providers.dart';

/// Modern Circular Category Selector for BazaarShodai.
/// Features:
/// - Mathematically perfect anti-aliased circular avatars using ClipOval
/// - Premium active state with emerald accent ring, soft glowing elevation, and active indicator
/// - Tactile responsive taps with subtle scaling
/// - Seamless asset and network image support with graceful progressive loading & pastel fallbacks
/// - Full dark mode support
class CategorySelector extends ConsumerWidget {
  const CategorySelector({super.key});

  Map<String, dynamic> _getCategoryStyle(String name, {String? imageUrl, bool isSelected = false}) {
    final lower = name.toLowerCase();
    final customImage = (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null;

    if (lower == 'all') {
      return {
        'bg': isSelected ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
        'iconColor': isSelected ? const Color(0xFF047857) : const Color(0xFF475569),
        'icon': Icons.dashboard_rounded,
        'image': null,
      };
    } else if (lower.contains('veg')) {
      return {
        'bg': const Color(0xFFE8F8EE),
        'iconColor': const Color(0xFF2E7D32),
        'icon': Icons.eco_rounded,
        'image': customImage ?? 'assets/images/categories/vegetables.jpg',
      };
    } else if (lower.contains('fruit')) {
      return {
        'bg': const Color(0xFFFFEBEA),
        'iconColor': const Color(0xFFE53935),
        'icon': Icons.apple_rounded,
        'image': customImage,
      };
    } else if (lower.contains('fish') || lower.contains('meat')) {
      return {
        'bg': const Color(0xFFE8F1FD),
        'iconColor': const Color(0xFF1E88E5),
        'icon': Icons.set_meal_rounded,
        'image': customImage ?? 'assets/images/categories/fish_meat.jpg',
      };
    } else if (lower.contains('spice') || lower.contains('oil')) {
      return {
        'bg': const Color(0xFFFFF7E6),
        'iconColor': const Color(0xFFF57C00),
        'icon': Icons.water_drop_rounded,
        'image': customImage ?? 'assets/images/categories/spices_oil.jpg',
      };
    } else if (lower.contains('dairy') || lower.contains('egg')) {
      return {
        'bg': const Color(0xFFE6F5FD),
        'iconColor': const Color(0xFF0288D1),
        'icon': Icons.egg_rounded,
        'image': customImage ?? 'assets/images/categories/dairy_eggs.jpg',
      };
    } else if (lower.contains('rice') || lower.contains('grain')) {
      return {
        'bg': const Color(0xFFFFF0E6),
        'iconColor': const Color(0xFFD84315),
        'icon': Icons.rice_bowl_rounded,
        'image': customImage,
      };
    } else {
      return {
        'bg': const Color(0xFFF1F5F9),
        'iconColor': const Color(0xFF475569),
        'icon': Icons.grid_view_rounded,
        'image': customImage,
      };
    }
  }

  Widget _buildFallbackIcon(Map<String, dynamic> style, bool isSelected) {
    return Container(
      color: style['bg'] as Color,
      alignment: Alignment.center,
      child: Icon(
        style['icon'] as IconData,
        size: 26,
        color: style['iconColor'] as Color,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 104,
      child: categoriesAsync.when(
        data: (categories) {
          final items = [
            const CategoryModel(
              id: 'cat_all',
              name: 'All',
              icon: 'dashboard',
            ),
            ...categories,
          ];

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final category = items[index];
              final categoryName = category.name;
              final isSelected = (selectedCategory == null && categoryName == 'All') ||
                  selectedCategory == categoryName;
              final style = _getCategoryStyle(
                categoryName,
                imageUrl: category.imageUrl,
                isSelected: isSelected,
              );
              final imagePath = style['image'] as String?;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  ref.read(selectedCategoryProvider.notifier).selectCategory(categoryName);
                },
                child: SizedBox(
                  width: 66,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Perfect Circular Outer Ring + ClipOval Inner Image
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: 60,
                        height: 60,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? (isDark ? const Color(0xFF064E3B) : Colors.white)
                              : (isDark ? const Color(0xFF1E293B) : Colors.white),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF059669)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            width: isSelected ? 2.2 : 1.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF059669).withValues(alpha: 0.28),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: ClipOval(
                          child: Container(
                            color: style['bg'] as Color,
                            width: double.infinity,
                            height: double.infinity,
                            child: imagePath != null && imagePath.isNotEmpty
                                ? (imagePath.startsWith('assets/')
                                    ? Image.asset(
                                        imagePath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => _buildFallbackIcon(style, isSelected),
                                      )
                                    : Image.network(
                                        imagePath,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return Center(
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                value: progress.expectedTotalBytes != null
                                                    ? progress.cumulativeBytesLoaded /
                                                        progress.expectedTotalBytes!
                                                    : null,
                                                color: const Color(0xFF059669),
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (_, _, _) => _buildFallbackIcon(style, isSelected),
                                      ))
                                : _buildFallbackIcon(style, isSelected),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Category Label with active emphasis
                      Text(
                        categoryName,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155)),
                          height: 1.15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Subtle Active Pill Indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: isSelected ? 16 : 0,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, _) => SizedBox(
            width: 66,
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 44,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }
}
