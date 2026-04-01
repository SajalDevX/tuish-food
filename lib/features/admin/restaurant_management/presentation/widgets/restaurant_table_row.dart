import 'package:flutter/material.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/cached_image.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';

class RestaurantTableRow extends StatelessWidget {
  const RestaurantTableRow({
    super.key,
    required this.restaurant,
    this.onTap,
    this.onEdit,
    this.onToggleStatus,
    this.onDelete,
    this.onMenuTap,
  });

  final Restaurant restaurant;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onDelete;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.s8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppSizes.borderRadiusM,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSizes.borderRadiusM,
        child: Padding(
          padding: AppSizes.paddingAllM,
          child: Row(
            children: [
              // Restaurant image
              ClipRRect(
                borderRadius: AppSizes.borderRadiusS,
                child: restaurant.imageUrl.isNotEmpty
                    ? CachedImage(
                        imageUrl: restaurant.imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: AppColors.background,
                        child: const Icon(
                          Icons.restaurant_rounded,
                          color: AppColors.textHint,
                        ),
                      ),
              ),
              const SizedBox(width: AppSizes.s12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            style: AppTypography.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Status indicator
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: restaurant.isActive
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      restaurant.cuisineTypesLabel,
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.s4),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.starFilled,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          restaurant.averageRating.toStringAsFixed(1),
                          style: AppTypography.labelSmall,
                        ),
                        const SizedBox(width: AppSizes.s12),
                        Text(
                          '${restaurant.totalOrders} orders',
                          style: AppTypography.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSizes.borderRadiusS,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call();
                    case 'menu':
                      onMenuTap?.call();
                    case 'toggle':
                      onToggleStatus?.call();
                    case 'delete':
                      onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'menu',
                    child: Row(
                      children: [
                        Icon(Icons.menu_book_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Manage Menu'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          restaurant.isActive
                              ? Icons.toggle_off_rounded
                              : Icons.toggle_on_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(restaurant.isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded,
                            size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
