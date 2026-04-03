import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/cached_image.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';
import 'package:tuish_food/routing/route_names.dart';

/// A compact horizontal list tile version of a restaurant.
/// Suitable for search results and compact lists.
class RestaurantListTile extends StatefulWidget {
  const RestaurantListTile({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  State<RestaurantListTile> createState() => _RestaurantListTileState();
}

class _RestaurantListTileState extends State<RestaurantListTile> {
  bool _isNavigating = false;

  Future<void> _openRestaurant() async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    try {
      await context.pushNamed(
        RouteNames.restaurantDetail,
        pathParameters: {'id': widget.restaurant.id},
      );
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _openRestaurant,
      borderRadius: AppSizes.borderRadiusM,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s16,
          vertical: AppSizes.s8,
        ),
        child: Row(
          children: [
            // Thumbnail image
            ClipRRect(
              borderRadius: AppSizes.borderRadiusS,
              child: CachedImage(
                imageUrl: widget.restaurant.imageUrl,
                width: 72,
                height: 72,
              ),
            ),
            const SizedBox(width: AppSizes.s12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.restaurant.name,
                    style: AppTypography.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.s4),
                  Text(
                    widget.restaurant.cuisineTypesLabel,
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.s4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: AppSizes.iconS,
                        color: AppColors.starFilled,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        widget.restaurant.averageRating.toStringAsFixed(1),
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSizes.s8),
                      const Icon(
                        Icons.access_time_rounded,
                        size: AppSizes.iconS,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        widget.restaurant.deliveryTimeLabel,
                        style: AppTypography.labelSmall,
                      ),
                      const SizedBox(width: AppSizes.s8),
                      Text(
                        widget.restaurant.deliveryFeeLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: widget.restaurant.deliveryFee == 0
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Open/Closed indicator
            if (!widget.restaurant.isOpen)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s8,
                  vertical: AppSizes.s4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: AppSizes.borderRadiusS,
                ),
                child: Text(
                  'Closed',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
