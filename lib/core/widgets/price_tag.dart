import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';

class PriceTag extends StatelessWidget {
  const PriceTag({
    super.key,
    required this.price,
    this.currencySymbol = '\u20B9',
    this.style,
    this.discountedPrice,
  });

  /// The current (or original, if discounted) price.
  final double price;

  /// Currency symbol to display before the price. Defaults to the Indian Rupee sign.
  final String currencySymbol;

  /// Custom text style for the displayed price.
  final TextStyle? style;

  /// If provided, this is the new lower price, and [price] is shown with a
  /// strikethrough as the original price.
  final double? discountedPrice;

  String _formatPrice(double value) {
    // Remove trailing zeroes for whole numbers, keep 2 decimals otherwise.
    if (value == value.roundToDouble()) {
      return '$currencySymbol${value.toInt()}';
    }
    return '$currencySymbol${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    if (discountedPrice != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            _formatPrice(discountedPrice!),
            style: style ?? AppTypography.price,
          ),
          const SizedBox(width: AppSizes.s8),
          Text(
            _formatPrice(price),
            style: AppTypography.priceStrikethrough,
          ),
        ],
      );
    }

    return Text(
      _formatPrice(price),
      style: style ?? AppTypography.price,
    );
  }
}
