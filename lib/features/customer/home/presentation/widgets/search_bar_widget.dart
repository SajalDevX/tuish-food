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
    return GestureDetector(
      onTap: () => context.push(RoutePaths.searchScreen),
      child: Container(
        height: AppSizes.buttonHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppSizes.borderRadiusM,
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppColors.textHint,
              size: AppSizes.iconM,
            ),
            const SizedBox(width: AppSizes.s12),
            Text(
              AppStrings.searchRestaurants,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
