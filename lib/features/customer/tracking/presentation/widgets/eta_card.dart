import 'package:flutter/material.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/enums/order_status.dart';

class EtaCard extends StatelessWidget {
  const EtaCard({
    super.key,
    required this.status,
    this.estimatedMinutes,
    this.distanceKm,
  });

  final OrderStatus status;
  final int? estimatedMinutes;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSizes.paddingAllM,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSizes.borderRadiusL,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status row
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: status.isActive ? AppColors.success : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.s8),
              Text(
                status.displayName,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.s12),

          // ETA and distance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // ETA
              _InfoColumn(
                icon: Icons.access_time_rounded,
                value: estimatedMinutes != null
                    ? '$estimatedMinutes min'
                    : '--',
                label: 'Estimated Time',
              ),

              // Divider
              Container(
                width: 1,
                height: 40,
                color: AppColors.divider,
              ),

              // Distance
              _InfoColumn(
                icon: Icons.route_rounded,
                value: distanceKm != null
                    ? '${distanceKm!.toStringAsFixed(1)} km'
                    : '--',
                label: 'Distance',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.iconS, color: AppColors.primary),
            const SizedBox(width: AppSizes.s4),
            Text(value, style: AppTypography.titleMedium),
          ],
        ),
        const SizedBox(height: AppSizes.s4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
