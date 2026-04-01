import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/cached_image.dart';
import 'package:tuish_food/features/customer/cart/domain/entities/cart_item.dart';

class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.uniqueKey),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.s24),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s16,
          vertical: AppSizes.s12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Item image
            ClipRRect(
              borderRadius: AppSizes.borderRadiusS,
              child: item.imageUrl.isNotEmpty
                  ? CachedImage(
                      imageUrl: item.imageUrl,
                      width: 56,
                      height: 56,
                      borderRadius: AppSizes.borderRadiusS,
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: AppSizes.borderRadiusS,
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: AppColors.textHint,
                        size: 24,
                      ),
                    ),
            ),
            const SizedBox(width: AppSizes.s12),

            // Name + customization details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTypography.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.selectedCustomizations.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.selectedCustomizations.values
                          .expand((v) => v)
                          .join(', '),
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSizes.s4),
                  Text(
                    '\u20B9${item.price.toStringAsFixed(0)}',
                    style: AppTypography.priceSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSizes.s12),

            // Quantity controls + total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Quantity selector
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: AppSizes.borderRadiusS,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: onDecrement,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.s8,
                            vertical: AppSizes.s4,
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.s8,
                        ),
                        child: Text(
                          '${item.quantity}',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: onIncrement,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.s8,
                            vertical: AppSizes.s4,
                          ),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.s4),

                // Total price
                Text(
                  '\u20B9${item.totalPrice.toStringAsFixed(0)}',
                  style: AppTypography.priceSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
