import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/features/customer/home/domain/entities/category.dart';

/// A rounded chip / card displaying a category icon and name.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
  });

  final FoodCategory category;
  final bool isSelected;
  final VoidCallback? onTap;

  /// Maps category ids to Material icons for display.
  static const Map<String, IconData> _categoryIcons = {
    'pizza': Icons.local_pizza_outlined,
    'burger': Icons.lunch_dining_outlined,
    'sushi': Icons.set_meal_outlined,
    'chinese': Icons.ramen_dining_outlined,
    'indian': Icons.rice_bowl_outlined,
    'mexican': Icons.kebab_dining_outlined,
    'thai': Icons.soup_kitchen_outlined,
    'italian': Icons.dinner_dining_outlined,
    'dessert': Icons.icecream_outlined,
    'healthy': Icons.eco_outlined,
    'coffee': Icons.coffee_outlined,
    'fast_food': Icons.fastfood_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcons[category.id] ?? Icons.restaurant_outlined;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : (isDark ? AppColors.darkCard : AppColors.surface),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkDivider : AppColors.divider),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.glassTextSecondary
                          : AppColors.textSecondary),
                size: AppSizes.iconL,
              ),
            ),
            const SizedBox(height: AppSizes.s8),
            Text(
              category.name,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.glassTextBody
                          : AppColors.textSecondary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
