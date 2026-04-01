import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/enums/order_status.dart';

/// A large status-update button whose label and color change based on
/// the current delivery status:
///   readyForPickup  -> "Navigate to Restaurant"
///   pickedUp        -> "Mark as Picked Up" (actually means heading to customer)
///   onTheWay        -> "Mark as Delivered"
class StatusUpdateButton extends StatelessWidget {
  const StatusUpdateButton({
    super.key,
    required this.currentStatus,
    required this.onPressed,
    this.isLoading = false,
  });

  final OrderStatus currentStatus;
  final VoidCallback? onPressed;
  final bool isLoading;

  String get _label {
    return switch (currentStatus) {
      OrderStatus.readyForPickup => AppStrings.navigate,
      OrderStatus.pickedUp => AppStrings.markPickedUp,
      OrderStatus.onTheWay => AppStrings.markDelivered,
      _ => 'Update Status',
    };
  }

  IconData get _icon {
    return switch (currentStatus) {
      OrderStatus.readyForPickup => Icons.navigation_outlined,
      OrderStatus.pickedUp => Icons.check_circle_outline,
      OrderStatus.onTheWay => Icons.done_all_rounded,
      _ => Icons.update,
    };
  }

  Color get _backgroundColor {
    return switch (currentStatus) {
      OrderStatus.readyForPickup => AppColors.statusReady,
      OrderStatus.pickedUp => AppColors.statusPickedUp,
      OrderStatus.onTheWay => AppColors.statusDelivered,
      _ => AppColors.secondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight + 4,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _backgroundColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _backgroundColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: AppSizes.borderRadiusM,
          ),
          elevation: AppSizes.elevationCard,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_icon, size: AppSizes.iconM),
                  const SizedBox(width: AppSizes.s8),
                  Text(
                    _label,
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
