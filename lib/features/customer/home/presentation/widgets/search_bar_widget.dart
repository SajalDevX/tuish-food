import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/routing/route_paths.dart';

/// A styled search bar that navigates to the search screen on tap.
/// This is a non-interactive display widget -- tapping it opens the
/// full search screen.
class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push(RoutePaths.searchScreen),
      child: Container(
        height: AppSizes.buttonHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.surface,
          borderRadius: AppSizes.borderRadiusM,
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: isDark
                  ? AppColors.glassTextSecondary
                  : AppColors.textSecondary,
              size: AppSizes.iconM,
            ),
            const SizedBox(width: AppSizes.s12),
            Text(
              AppStrings.searchRestaurants,
              style: AppTypography.bodyLarge.copyWith(
                color: isDark ? AppColors.glassTextHint : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
