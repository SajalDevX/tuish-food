import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/tuish_card.dart';

class PromotionCard extends StatelessWidget {
  const PromotionCard({
    super.key,
    required this.data,
    this.onTap,
  });

  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final code = data['code'] as String? ?? '';
    final title = data['title'] as String? ?? 'Untitled';
    final discountType = data['discountType'] as String? ?? 'percentage';
    final discountValue =
        (data['discountValue'] as num?)?.toDouble() ?? 0;
    final validFrom = (data['validFrom'] as Timestamp?)?.toDate();
    final validTo = (data['validTo'] as Timestamp?)?.toDate();
    final usageCount = data['usageCount'] as int? ?? 0;
    final usageLimit = data['usageLimit'] as int? ?? 0;
    final isActive = data['isActive'] as bool? ?? false;

    final now = DateTime.now();
    final isExpired = validTo != null && validTo.isBefore(now);
    final effectiveActive = isActive && !isExpired;

    final dateFormat = DateFormat('MMM dd, yyyy');

    // Build discount display
    final discountDisplay = discountType == 'percentage'
        ? '${discountValue.toStringAsFixed(0)}% OFF'
        : '\u20B9${discountValue.toStringAsFixed(0)} OFF';

    return TuishCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSizes.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Code badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s12,
                  vertical: AppSizes.s4,
                ),
                decoration: BoxDecoration(
                  color: effectiveActive
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.textHint.withValues(alpha: 0.1),
                  borderRadius: AppSizes.borderRadiusPill,
                  border: Border.all(
                    color: effectiveActive
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                ),
                child: Text(
                  code.toUpperCase(),
                  style: AppTypography.labelLarge.copyWith(
                    color: effectiveActive
                        ? AppColors.primary
                        : AppColors.textHint,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              // Active/Expired indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: effectiveActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.textHint.withValues(alpha: 0.1),
                  borderRadius: AppSizes.borderRadiusPill,
                ),
                child: Text(
                  effectiveActive ? 'Active' : 'Expired',
                  style: AppTypography.labelSmall.copyWith(
                    color: effectiveActive
                        ? AppColors.success
                        : AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s12),

          // Title
          Text(title, style: AppTypography.titleSmall),
          const SizedBox(height: AppSizes.s4),

          // Discount display
          Text(
            discountDisplay,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.s12),

          // Validity dates
          if (validFrom != null || validTo != null)
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: AppSizes.s4),
                Text(
                  '${validFrom != null ? dateFormat.format(validFrom) : 'N/A'}'
                  ' - '
                  '${validTo != null ? dateFormat.format(validTo) : 'N/A'}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          const SizedBox(height: AppSizes.s4),

          // Usage
          Row(
            children: [
              const Icon(Icons.people_outline,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: AppSizes.s4),
              Text(
                usageLimit > 0
                    ? 'Used: $usageCount / $usageLimit'
                    : 'Used: $usageCount (unlimited)',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
