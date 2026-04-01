import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/extensions/datetime_extensions.dart';
import 'package:tuish_food/core/widgets/cached_image.dart';
import 'package:tuish_food/core/widgets/status_badge.dart';
import 'package:tuish_food/core/widgets/tuish_card.dart';
import 'package:tuish_food/features/customer/orders/domain/entities/order.dart';
import 'package:tuish_food/routing/route_names.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    return TuishCard(
      onTap: () {
        context.pushNamed(
          RouteNames.orderDetail,
          pathParameters: {'orderId': order.id},
        );
      },
      margin: const EdgeInsets.only(bottom: AppSizes.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant info row
          Row(
            children: [
              if (order.restaurantImageUrl != null)
                CachedImage(
                  imageUrl: order.restaurantImageUrl!,
                  width: 48,
                  height: 48,
                  borderRadius: AppSizes.borderRadiusS,
                ),
              if (order.restaurantImageUrl != null)
                const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.restaurantName ?? 'Restaurant',
                      style: AppTypography.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      'Order #${order.orderNumber}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: order.status),
            ],
          ),

          const SizedBox(height: AppSizes.s12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSizes.s12),

          // Items summary and date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.totalItemCount} item${order.totalItemCount != 1 ? 's' : ''}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                order.createdAt.formattedDateTime,
                style: AppTypography.bodySmall,
              ),
            ],
          ),

          const SizedBox(height: AppSizes.s12),

          // Total and action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\u20B9${order.totalAmount.toStringAsFixed(2)}',
                style: AppTypography.price,
              ),
              if (order.isActive)
                FilledButton.icon(
                  onPressed: () {
                    context.pushNamed(
                      RouteNames.orderTracking,
                      pathParameters: {'orderId': order.id},
                    );
                  },
                  icon: const Icon(Icons.delivery_dining, size: 18),
                  label: const Text('Track'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s16,
                      vertical: AppSizes.s8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSizes.borderRadiusPill,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
