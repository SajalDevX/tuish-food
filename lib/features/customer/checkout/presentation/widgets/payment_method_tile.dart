import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/features/customer/checkout/domain/entities/payment.dart';

class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon {
    return switch (method) {
      PaymentMethod.card => Icons.credit_card,
      PaymentMethod.cashOnDelivery => Icons.money,
    };
  }

  String get _subtitle {
    return switch (method) {
      PaymentMethod.card => 'Pay using credit or debit card',
      PaymentMethod.cashOnDelivery => 'Pay when your order arrives',
    };
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSizes.borderRadiusM,
      child: Container(
        padding: AppSizes.paddingAllM,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.surface,
          borderRadius: AppSizes.borderRadiusM,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.background,
                borderRadius: AppSizes.borderRadiusS,
              ),
              child: Icon(
                _icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSizes.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.displayName,
                    style: AppTypography.titleSmall.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(_subtitle, style: AppTypography.bodySmall),
                ],
              ),
            ),
            // ignore: deprecated_member_use
            Radio<bool>(
              value: true,
              // ignore: deprecated_member_use
              groupValue: isSelected ? true : null,
              // ignore: deprecated_member_use
              onChanged: (_) => onTap(),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
