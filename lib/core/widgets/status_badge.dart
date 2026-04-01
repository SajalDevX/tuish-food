import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/enums/order_status.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
  });

  final OrderStatus status;

  Color get _backgroundColor {
    return switch (status) {
      OrderStatus.placed => AppColors.statusPlaced,
      OrderStatus.confirmed => AppColors.statusConfirmed,
      OrderStatus.preparing => AppColors.statusPreparing,
      OrderStatus.readyForPickup => AppColors.statusReady,
      OrderStatus.pickedUp => AppColors.statusPickedUp,
      OrderStatus.onTheWay => AppColors.statusOnTheWay,
      OrderStatus.delivered => AppColors.statusDelivered,
      OrderStatus.cancelled => AppColors.statusCancelled,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s12,
        vertical: AppSizes.s4,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: AppSizes.borderRadiusPill,
      ),
      child: Text(
        status.displayName,
        style: AppTypography.labelMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
