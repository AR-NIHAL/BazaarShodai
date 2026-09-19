import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/buyer_providers.dart';

/// Circular pastel category selector matching BazaarShodai reference design.
/// Each category features a soft pastel background, matching iconography,
/// and clean typography label below.
class CategorySelector extends ConsumerWidget {
  const CategorySelector({super.key});

  Map<String, dynamic> _getCategoryStyle(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('veg')) {
      return {
        'bg': const Color(0xFFE8F8EE),
        'iconColor': const Color(0xFF2E7D32),
        'icon': Icons.eco_rounded,
      };
    } else if (lower.contains('fruit')) {
      return {
        'bg': const Color(0xFFFFEBEA),
        'iconColor': const Color(0xFFE53935),
        'icon': Icons.apple_rounded,
      };
    } else if (lower.contains('fish') || lower.contains('meat')) {
      return {
        'bg': const Color(0xFFE8F1FD),
        'iconColor': const Color(0xFF1E88E5),
        'icon': Icons.set_meal_rounded,
      };
    } else if (lower.contains('spice') || lower.contains('oil')) {
      return {
        'bg': const Color(0xFFFFF7E6),
        'iconColor': const Color(0xFFF57C00),
        'icon': Icons.water_drop_rounded,
      };
    } else if (lower.contains('dairy') || lower.contains('egg')) {
      return {
        'bg': const Color(0xFFE6F5FD),
        'iconColor': const Color(0xFF0288D1),
        'icon': Icons.egg_rounded,
      };
    } else if (lower.contains('rice') || lower.contains('grain')) {
      return {
        'bg': const Color(0xFFFFF0E6),
        'iconColor': const Color(0xFFD84315),
        'icon': Icons.rice_bowl_rounded,
      };
    } else {
      return {
        'bg': const Color(0xFFF1F5F9),
        'iconColor': const Color(0xFF475569),
        'icon': Icons.grid_view_rounded,
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
            'All',
            ...categories.map((c) => c.name),
          ];

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final categoryName = items[index];
              final isSelected = (selectedCategory == null && categoryName == 'All') ||
                  selectedCategory == categoryName;
              final style = _getCategoryStyle(categoryName);

              return GestureDetector(
                onTap: () {
                  ref.read(selectedCategoryProvider.notifier).selectCategory(categoryName);
                },
                child: SizedBox(
                  width: 62,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Circular Pastel Container
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        height: 56,
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
                        child: Icon(
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
