import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';

class CartSummary extends StatelessWidget {
  const CartSummary({
    super.key,
    required this.subtotal,
    this.deliveryFee = 40.0,
    this.discount = 0.0,
    this.taxRate = 0.05,
    this.tip = 0.0,
  });

  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double taxRate;
  final double tip;

  double get taxes => subtotal * taxRate;
  double get total => subtotal + deliveryFee + taxes + tip - discount;

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
          Text('Bill Details', style: AppTypography.titleSmall),
          const SizedBox(height: AppSizes.s12),

          _PriceRow(label: 'Item Total', amount: subtotal),
          const SizedBox(height: AppSizes.s8),

          _PriceRow(label: 'Delivery Fee', amount: deliveryFee),
          const SizedBox(height: AppSizes.s8),

          _PriceRow(label: 'Taxes & Charges', amount: taxes),

          if (tip > 0) ...[
            const SizedBox(height: AppSizes.s8),
            _PriceRow(label: 'Tip', amount: tip),
          ],

          if (discount > 0) ...[
            const SizedBox(height: AppSizes.s8),
            _PriceRow(
              label: 'Discount',
              amount: -discount,
              valueColor: AppColors.success,
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.s12),
            child: Divider(),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('To Pay', style: AppTypography.titleMedium),
              Text(
                '\u20B9${total.toStringAsFixed(0)}',
                style: AppTypography.price,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.amount, this.valueColor});

  final String label;
  final double amount;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final isNegative = amount < 0;
    final displayAmount = isNegative ? amount.abs() : amount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '${isNegative ? '-' : ''}\u20B9${displayAmount.toStringAsFixed(0)}',
          style: AppTypography.bodyMedium.copyWith(
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
