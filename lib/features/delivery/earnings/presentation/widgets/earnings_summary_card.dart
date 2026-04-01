import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/utils/formatters.dart';
import 'package:tuish_food/core/widgets/tuish_card.dart';

/// Summary card showing total earnings, delivery count, and average per delivery.
class EarningsSummaryCard extends StatelessWidget {
  const EarningsSummaryCard({
    super.key,
    required this.totalEarnings,
    required this.deliveriesCount,
    required this.averagePerDelivery,
    this.label = "Today's Earnings",
  });

  final double totalEarnings;
  final int deliveriesCount;
  final double averagePerDelivery;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TuishCard(
      color: AppColors.secondary,
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSizes.s8),
          Text(
            Formatters.formatCurrency(totalEarnings),
            style: AppTypography.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SummaryItem(
                label: 'Deliveries',
                value: '$deliveriesCount',
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _SummaryItem(
                label: 'Average',
                value: Formatters.formatCurrency(averagePerDelivery),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSizes.s4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
