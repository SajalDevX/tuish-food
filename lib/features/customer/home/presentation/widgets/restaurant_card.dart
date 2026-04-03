import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/cached_image.dart';
import 'package:tuish_food/core/widgets/tuish_card.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';

/// A card widget displaying a restaurant's image, name, cuisine types,
/// rating, delivery time, and delivery fee. Tapping navigates to
/// the restaurant detail screen.
class RestaurantCard extends StatelessWidget {
  const RestaurantCard({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TuishCard(
      margin: const EdgeInsets.only(bottom: AppSizes.s12),
      padding: EdgeInsets.zero,
      onTap: () {
        context.push('/customer/home/restaurant/${restaurant.id}');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant image
          Stack(
            children: [
              Hero(
                tag: 'restaurant_image_${restaurant.id}',
                child: CachedImage(
                  imageUrl: restaurant.imageUrl,
                  height: AppSizes.cardImageHeight,
                  width: double.infinity,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusL),
                  ),
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
                    color: Colors.black54,
                    borderRadius: AppSizes.borderRadiusS,
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
                          color: Colors.white,
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
                        top: Radius.circular(AppSizes.radiusL),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s16,
                        vertical: AppSizes.s8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: AppSizes.borderRadiusS,
                      ),
                      child: Text(
                        'Currently Closed',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Restaurant info
          Padding(
            padding: const EdgeInsets.all(AppSizes.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and rating row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        restaurant.name,
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.glassTextPrimary
                              : AppColors.textPrimary,
                        ),
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
                              color: isDark
                                  ? AppColors.glassTextPrimary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.s8),

                // Cuisine types
                Text(
                  restaurant.cuisineTypesLabel,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.glassTextSecondary
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

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
                            : (isDark
                                  ? AppColors.glassTextSecondary
                                  : AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: AppSizes.s16),
                    Text(
                      restaurant.priceLevelLabel,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.glassTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
