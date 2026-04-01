import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/utils/formatters.dart';
import 'package:tuish_food/features/delivery/earnings/domain/entities/earnings.dart';

/// A single tile in the payout/earnings history list.
class PayoutHistoryTile extends StatelessWidget {
  const PayoutHistoryTile({
    super.key,
    required this.earnings,
  });

  final Earnings earnings;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s4),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(AppSizes.s8),
            decoration: BoxDecoration(
              color: earnings.isPaidOut
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: AppSizes.borderRadiusS,
            ),
            child: Icon(
              earnings.isPaidOut
                  ? Icons.check_circle_outline
                  : Icons.pending_outlined,
              color: earnings.isPaidOut ? AppColors.success : AppColors.secondary,
              size: AppSizes.iconM,
            ),
          ),
          const SizedBox(width: AppSizes.s12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${earnings.orderNumber}',
                  style: AppTypography.titleSmall,
                ),
                const SizedBox(height: AppSizes.s4),
                Text(
                  dateFormat.format(earnings.date),
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),

          // Amount breakdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.formatCurrency(earnings.totalEarned),
                style: AppTypography.priceSmall.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              if (earnings.tip > 0)
                Text(
                  '+${Formatters.formatCurrency(earnings.tip)} tip',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
