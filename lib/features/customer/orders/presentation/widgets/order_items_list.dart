import 'package:flutter/material.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/features/customer/orders/domain/entities/order.dart';

class OrderItemsList extends StatelessWidget {
  const OrderItemsList({super.key, required this.items});

  final List<OrderItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items',
          style: AppTypography.titleMedium,
        ),
        const SizedBox(height: AppSizes.s12),
        ...items.map((item) => _OrderItemTile(item: item)),
      ],
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quantity badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppSizes.borderRadiusS,
            ),
            alignment: Alignment.center,
            child: Text(
              '${item.quantity}x',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.s12),

          // Name and customizations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTypography.bodyMedium,
                ),
                if (item.customizations.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.s4),
                  Text(
                    item.customizations.join(', '),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.specialInstructions != null &&
                    item.specialInstructions!.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.s4),
                  Text(
                    'Note: ${item.specialInstructions}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: AppSizes.s8),

          // Price
          Text(
            '\u20B9${item.totalPrice.toStringAsFixed(2)}',
            style: AppTypography.priceSmall,
          ),
        ],
      ),
    );
  }
}
