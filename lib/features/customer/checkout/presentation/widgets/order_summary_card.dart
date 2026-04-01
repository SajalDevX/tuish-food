import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/features/customer/cart/domain/entities/cart_item.dart';

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    super.key,
    required this.items,
    required this.restaurantName,
  });

  final List<CartItem> items;
  final String restaurantName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSizes.paddingAllM,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSizes.borderRadiusM,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant name
          Row(
            children: [
              const Icon(
                Icons.storefront,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.s8),
              Text(restaurantName, style: AppTypography.titleSmall),
            ],
          ),
          const SizedBox(height: AppSizes.s12),
          const Divider(),
          const SizedBox(height: AppSizes.s8),

          // Items
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.s8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quantity
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${item.quantity}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.s12),

                  // Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: AppTypography.bodyMedium),
                        if (item.selectedCustomizations.isNotEmpty)
                          Text(
                            item.selectedCustomizations.values
                                .expand((v) => v)
                                .join(', '),
                            style: AppTypography.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.s12),

                  // Price
                  Text(
                    '\u20B9${item.totalPrice.toStringAsFixed(0)}',
                    style: AppTypography.priceSmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
