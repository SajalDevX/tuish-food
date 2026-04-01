import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/cached_image.dart';
import 'package:tuish_food/core/widgets/price_tag.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_item.dart';

class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onAddToCart,
    this.quantity = 0,
    this.onIncrement,
    this.onDecrement,
  });

  final MenuItem item;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSizes.borderRadiusM,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s16,
          vertical: AppSizes.s12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Veg/Non-veg indicator
                  Row(
                    children: [
                      _VegIndicator(isVeg: item.isVegetarian),
                      if (item.isPopular) ...[
                        const SizedBox(width: AppSizes.s8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.s8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: AppSizes.borderRadiusS,
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Popular',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSizes.s4),

                  // Name
                  Text(
                    item.name,
                    style: AppTypography.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.s4),

                  // Price
                  PriceTag(
                    price: item.price,
                    discountedPrice: item.hasDiscount
                        ? item.discountedPrice
                        : null,
                    style: AppTypography.priceSmall,
                  ),
                  const SizedBox(height: AppSizes.s4),

                  // Description
                  Text(
                    item.description,
                    style: AppTypography.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Spice level
                  if (item.spiceLevel > 0) ...[
                    const SizedBox(height: AppSizes.s4),
                    Row(
                      children: List.generate(
                        item.spiceLevel.clamp(0, 3),
                        (index) => const Padding(
                          padding: EdgeInsets.only(right: 2),
                          child: Icon(
                            Icons.local_fire_department,
                            size: 14,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: AppSizes.s12),

            // Image + Add button
            Column(
              children: [
                // Image
                ClipRRect(
                  borderRadius: AppSizes.borderRadiusM,
                  child: item.imageUrl.isNotEmpty
                      ? CachedImage(
                          imageUrl: item.imageUrl,
                          width: AppSizes.menuItemImageSize,
                          height: AppSizes.menuItemImageSize,
                          borderRadius: AppSizes.borderRadiusM,
                        )
                      : Container(
                          width: AppSizes.menuItemImageSize,
                          height: AppSizes.menuItemImageSize,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: AppSizes.borderRadiusM,
                          ),
                          child: const Icon(
                            Icons.restaurant,
                            color: AppColors.textHint,
                          ),
                        ),
                ),
                const SizedBox(height: AppSizes.s8),

                // Add / Quantity selector
                if (!item.isAvailable)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s12,
                      vertical: AppSizes.s4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: AppSizes.borderRadiusS,
                    ),
                    child: Text(
                      'Unavailable',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  )
                else if (quantity > 0)
                  _QuantitySelector(
                    quantity: quantity,
                    onIncrement: onIncrement ?? () {},
                    onDecrement: onDecrement ?? () {},
                  )
                else
                  _AddButton(
                    onTap: onAddToCart,
                    hasCustomizations: item.hasCustomizations,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VegIndicator extends StatelessWidget {
  const _VegIndicator({required this.isVeg});
  final bool isVeg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border.all(
          color: isVeg ? AppColors.vegGreen : AppColors.nonVegRed,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isVeg ? AppColors.vegGreen : AppColors.nonVegRed,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap, required this.hasCustomizations});
  final VoidCallback onTap;
  final bool hasCustomizations;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSizes.borderRadiusS,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s24,
            vertical: AppSizes.s8,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSizes.borderRadiusS,
            border: Border.all(color: AppColors.primary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ADD',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (hasCustomizations)
                Text(
                  'Customisable',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppSizes.borderRadiusS,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onDecrement,
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.s12,
                vertical: AppSizes.s8,
              ),
              child: Icon(Icons.remove, size: 16, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s4),
            child: Text(
              '$quantity',
              style: AppTypography.labelLarge.copyWith(color: Colors.white),
            ),
          ),
          InkWell(
            onTap: onIncrement,
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.s12,
                vertical: AppSizes.s8,
              ),
              child: Icon(Icons.add, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
