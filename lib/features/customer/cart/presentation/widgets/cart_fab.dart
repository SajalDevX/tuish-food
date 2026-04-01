import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/features/customer/cart/presentation/providers/cart_provider.dart';
import 'package:tuish_food/routing/route_names.dart';

class CartFab extends ConsumerWidget {
  const CartFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartNotifierProvider);

    if (cart.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.goNamed(RouteNames.customerCart),
      child: Container(
        margin: const EdgeInsets.only(
          left: AppSizes.s32,
          right: AppSizes.s16,
          bottom: AppSizes.s8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s16,
          vertical: AppSizes.s12,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppSizes.borderRadiusM,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Item count badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.s8,
                vertical: AppSizes.s4,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: AppSizes.borderRadiusS,
              ),
              child: Text(
                '${cart.itemCount} item${cart.itemCount > 1 ? 's' : ''}',
                style: AppTypography.labelMedium.copyWith(color: Colors.white),
              ),
            ),
            const Spacer(),

            // Total and view cart
            Text(
              '\u20B9${cart.subtotal.toStringAsFixed(0)}',
              style: AppTypography.titleSmall.copyWith(color: Colors.white),
            ),
            const SizedBox(width: AppSizes.s8),
            Text(
              'View Cart',
              style: AppTypography.labelLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(width: AppSizes.s4),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }
}
