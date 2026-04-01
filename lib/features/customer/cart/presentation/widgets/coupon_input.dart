import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';

class CouponInput extends StatefulWidget {
  const CouponInput({
    super.key,
    required this.onApply,
    this.appliedCoupon,
    this.onRemove,
    this.isLoading = false,
  });

  final ValueChanged<String> onApply;
  final String? appliedCoupon;
  final VoidCallback? onRemove;
  final bool isLoading;

  @override
  State<CouponInput> createState() => _CouponInputState();
}

class _CouponInputState extends State<CouponInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.appliedCoupon != null) {
      return Container(
        padding: AppSizes.paddingAllM,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.05),
          borderRadius: AppSizes.borderRadiusM,
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer, color: AppColors.success, size: 20),
            const SizedBox(width: AppSizes.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.appliedCoupon!,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    'Coupon applied',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: widget.onRemove,
              child: Text(
                'Remove',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s12,
        vertical: AppSizes.s4,
      ),
      decoration: BoxDecoration(
        borderRadius: AppSizes.borderRadiusM,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_offer_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: AppSizes.s8),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter coupon code',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSizes.s12,
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              style: AppTypography.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: widget.isLoading
                ? null
                : () {
                    final code = _controller.text.trim();
                    if (code.isNotEmpty) {
                      widget.onApply(code);
                    }
                  },
            child: widget.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Apply',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
