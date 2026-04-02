import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/cached_image.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';

/// A card widget displaying a restaurant's image, name, cuisine types,
/// rating, delivery time, and delivery fee. Tapping navigates to
/// the restaurant detail screen.
class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    super.key,
    required this.restaurant,
  });

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/customer/home/restaurant/${restaurant.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.s12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: AppSizes.borderRadiusM,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant image
            Stack(
              children: [
                CachedImage(
                  imageUrl: restaurant.imageUrl,
                  height: AppSizes.cardImageHeight,
                  width: double.infinity,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusM),
                  ),
                ),
                // Delivery time badge
                Positioned(
                  bottom: AppSizes.s8,
                  right: AppSizes.s8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s8,
                      vertical: AppSizes.s4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: AppSizes.borderRadiusS,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: AppSizes.iconS,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSizes.s4),
                        Text(
                          restaurant.deliveryTimeLabel,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Closed overlay
                if (!restaurant.isOpen)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppSizes.radiusM),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.s16,
                          vertical: AppSizes.s8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: AppSizes.borderRadiusS,
                        ),
                        child: Text(
                          'Currently Closed',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Restaurant info
            Padding(
              padding: const EdgeInsets.all(AppSizes.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and rating row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: AppTypography.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSizes.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.s8,
                          vertical: AppSizes.s4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: AppSizes.borderRadiusS,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: AppSizes.iconS,
                              color: AppColors.starFilled,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              restaurant.averageRating.toStringAsFixed(1),
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.s4),

                  // Cuisine types
                  Text(
                    restaurant.cuisineTypesLabel,
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.s8),

                  // Delivery fee and price level
                  Row(
                    children: [
                      const Icon(
                        Icons.delivery_dining_outlined,
                        size: AppSizes.iconS,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSizes.s4),
                      Text(
                        restaurant.deliveryFeeLabel,
                        style: AppTypography.bodySmall.copyWith(
                          color: restaurant.deliveryFee == 0
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSizes.s16),
                      Text(
                        restaurant.priceLevelLabel,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
