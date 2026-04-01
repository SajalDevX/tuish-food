import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/utils/formatters.dart';

/// Floating card shown at the top of the navigation screen with
/// direction information (distance, ETA, destination name).
class TurnByTurnCard extends StatelessWidget {
  const TurnByTurnCard({
    super.key,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.destinationName,
    required this.directionIcon,
  });

  final double distanceKm;
  final int estimatedMinutes;
  final String destinationName;
  final IconData directionIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.s16,
        vertical: AppSizes.s8,
      ),
      padding: AppSizes.paddingAllM,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSizes.borderRadiusM,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.s12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: AppSizes.borderRadiusS,
            ),
            child: Icon(
              directionIcon,
              color: AppColors.secondary,
              size: AppSizes.iconL,
            ),
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Formatters.formatDistance(distanceKm),
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSizes.s4),
                Text(
                  destinationName,
                  style: AppTypography.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                Formatters.formatDuration(estimatedMinutes),
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text('ETA', style: AppTypography.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
