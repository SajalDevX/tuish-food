import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/utils/formatters.dart';
import 'package:tuish_food/features/delivery/dashboard/presentation/widgets/status_update_button.dart';

/// Bottom panel on the navigation screen showing pickup/delivery details
/// and the status-update button.
class DeliveryInfoPanel extends StatelessWidget {
  const DeliveryInfoPanel({
    super.key,
    required this.title,
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.currentStatus,
    required this.onStatusUpdate,
    this.isUpdating = false,
  });

  final String title;
  final String name;
  final String address;
  final double distanceKm;
  final int estimatedMinutes;
  final OrderStatus currentStatus;
  final VoidCallback onStatusUpdate;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSizes.paddingAllM,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSizes.s12),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: AppSizes.borderRadiusPill,
              ),
            ),

            // Title
            Row(
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${Formatters.formatDistance(distanceKm)} | ${Formatters.formatDuration(estimatedMinutes)}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s8),

            // Name & address
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.s8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: AppSizes.borderRadiusS,
                  ),
                  child: Icon(
                    title.toLowerCase().contains('pickup')
                        ? Icons.restaurant
                        : Icons.person,
                    color: AppColors.secondary,
                    size: AppSizes.iconM,
                  ),
                ),
                const SizedBox(width: AppSizes.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTypography.titleSmall),
                      Text(
                        address,
                        style: AppTypography.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s16),

            // Status update button
            StatusUpdateButton(
              currentStatus: currentStatus,
              isLoading: isUpdating,
              onPressed: onStatusUpdate,
            ),
          ],
        ),
      ),
    );
  }
}
