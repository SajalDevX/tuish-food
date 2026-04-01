import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';

class DeliveryAddressCard extends StatelessWidget {
  const DeliveryAddressCard({
    super.key,
    this.address,
    this.label,
    required this.onChangePressed,
  });

  final String? address;
  final String? label;
  final VoidCallback onChangePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSizes.paddingAllM,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSizes.borderRadiusM,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSizes.s8),
              Text('Delivery Address', style: AppTypography.titleSmall),
              const Spacer(),
              TextButton(
                onPressed: onChangePressed,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  address != null ? 'Change' : 'Add',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (address != null) ...[
            const SizedBox(height: AppSizes.s8),
            if (label != null) Text(label!, style: AppTypography.labelLarge),
            const SizedBox(height: AppSizes.s4),
            Text(
              address!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
            const SizedBox(height: AppSizes.s8),
            Text(
              'Please select a delivery address',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
