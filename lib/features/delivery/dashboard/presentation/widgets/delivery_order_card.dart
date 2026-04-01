import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/utils/formatters.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/core/widgets/tuish_card.dart';
import 'package:tuish_food/features/delivery/dashboard/domain/entities/delivery_order.dart';
import 'package:timeago/timeago.dart' as timeago;

class DeliveryOrderCard extends StatelessWidget {
  const DeliveryOrderCard({
    super.key,
    required this.order,
    this.onAccept,
    this.onReject,
    this.onTap,
  });

  final DeliveryOrder order;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TuishCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSizes.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: restaurant name & time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order.restaurantName,
                  style: AppTypography.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                timeago.format(order.createdAt),
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s8),

          // Customer area
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: AppSizes.iconS,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.s4),
              Expanded(
                child: Text(
                  order.customerAddress,
                  style: AppTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s12),

          // Stats row: distance, earnings, items
          Row(
            children: [
              _InfoChip(
                icon: Icons.directions_bike_outlined,
                label: Formatters.formatDistance(order.distanceKm),
              ),
              const SizedBox(width: AppSizes.s12),
              _InfoChip(
                icon: Icons.account_balance_wallet_outlined,
                label: Formatters.formatCurrency(order.deliveryFee),
              ),
              const SizedBox(width: AppSizes.s12),
              _InfoChip(
                icon: Icons.shopping_bag_outlined,
                label: '${order.itemsCount} items',
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s16),

          // Action buttons
          if (onAccept != null || onReject != null)
            Row(
              children: [
                if (onReject != null)
                  Expanded(
                    child: TuishButton.outlined(
                      label: AppStrings.rejectOrder,
                      onPressed: onReject,
                      isFullWidth: true,
                    ),
                  ),
                if (onAccept != null && onReject != null)
                  const SizedBox(width: AppSizes.s12),
                if (onAccept != null)
                  Expanded(
                    child: TuishButton.primary(
                      label: AppStrings.acceptOrder,
                      onPressed: onAccept,
                      isFullWidth: true,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconS, color: AppColors.secondary),
        const SizedBox(width: AppSizes.s4),
        Text(label, style: AppTypography.labelMedium),
      ],
    );
  }
}
