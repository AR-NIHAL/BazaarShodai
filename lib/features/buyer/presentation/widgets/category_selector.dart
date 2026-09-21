import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/category_model.dart';
import '../providers/buyer_providers.dart';

/// Circular pastel category selector matching BazaarShodai reference design.
/// Each category features its photographic category asset or soft pastel background with iconography,
/// and clean typography label below.
class CategorySelector extends ConsumerWidget {
  const CategorySelector({super.key});

  Map<String, dynamic> _getCategoryStyle(String name, {String? imageUrl}) {
    final lower = name.toLowerCase();
    final customImage = (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null;

    if (lower.contains('veg')) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return SizedBox(
      height: 94,
      child: categoriesAsync.when(
        data: (categories) {
          final items = [
            const CategoryModel(
              id: 'cat_all',
              name: 'All',
              icon: 'grid_view',
            ),
            ...categories,
          ];

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final category = items[index];
              final categoryName = category.name;
              final isSelected = (selectedCategory == null && categoryName == 'All') ||
                  selectedCategory == categoryName;
              final style = _getCategoryStyle(categoryName, imageUrl: category.imageUrl);
              final imagePath = style['image'] as String?;

              return GestureDetector(
                onTap: () {
                  ref.read(selectedCategoryProvider.notifier).selectCategory(categoryName);
                },
                child: SizedBox(
                  width: 62,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Circular Container (With Photo or Fallback Icon)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        height: 56,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: style['bg'] as Color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 2.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: imagePath != null && imagePath.isNotEmpty
                            ? (imagePath.startsWith('assets/')
                                ? Image.asset(
                                    imagePath,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      style['icon'] as IconData,
                                      size: 26,
                                      color: style['iconColor'] as Color,
                                    ),
                                  )
                                : Image.network(
                                    imagePath,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      style['icon'] as IconData,
                                      size: 26,
                                      color: style['iconColor'] as Color,
                                    ),
                                  ))
                            : Icon(
                                style['icon'] as IconData,
                                size: 26,
                                color: style['iconColor'] as Color,
                              ),
                      ),
                      const SizedBox(height: 6),

                      // Label
                      Text(
                        categoryName,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          height: 1.15,
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
          itemCount: 6,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, _) => SizedBox(
            width: 62,
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 40,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
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
