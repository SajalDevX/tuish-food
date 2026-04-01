import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/utils/formatters.dart';
import 'package:tuish_food/core/widgets/tuish_card.dart';

class DisputeCard extends StatelessWidget {
  const DisputeCard({
    super.key,
    required this.orderData,
    required this.orderId,
    this.onTap,
  });

  final Map<String, dynamic> orderData;
  final String orderId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final orderNumber = Formatters.formatOrderNumber(orderId);
    final customerName =
        orderData['customerName'] as String? ?? 'Unknown Customer';
    final issueType =
        orderData['disputeType'] as String? ?? 'General Complaint';
    final createdAt = (orderData['createdAt'] as Timestamp?)?.toDate();
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return TuishCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSizes.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: AppSizes.borderRadiusS,
                ),
                child: const Icon(
                  Icons.report_problem_outlined,
                  color: AppColors.warning,
                  size: AppSizes.iconM,
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(orderNumber, style: AppTypography.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      customerName,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s12),
          // Issue type
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s8,
              vertical: AppSizes.s4,
            ),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: AppSizes.borderRadiusPill,
            ),
            child: Text(
              issueType,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (createdAt != null) ...[
            const SizedBox(height: AppSizes.s8),
            Text(
              dateFormat.format(createdAt),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
