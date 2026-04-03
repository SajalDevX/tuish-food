import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/confirmation_dialog.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/core/widgets/glass_scaffold.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/features/customer/cart/presentation/providers/cart_provider.dart';
import 'package:tuish_food/features/customer/cart/presentation/widgets/cart_item_tile.dart';
import 'package:tuish_food/features/customer/cart/presentation/widgets/cart_summary.dart';
import 'package:tuish_food/features/customer/cart/presentation/widgets/coupon_input.dart';
import 'package:tuish_food/features/customer/checkout/presentation/providers/checkout_provider.dart';
import 'package:tuish_food/routing/route_names.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  String? _appliedCoupon;
  double _discount = 0.0;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartNotifierProvider);
    final cartNotifier = ref.read(cartNotifierProvider.notifier);

    if (cart.isEmpty) {
      return GlassScaffold(
        extendBodyBehindAppBar: false,
        appBar: const TuishAppBar(title: AppStrings.cart, centerTitle: false),
        body: EmptyStateWidget(
          message: 'Your cart is empty.\nBrowse restaurants to add items.',
          icon: Icons.shopping_cart_outlined,
          actionLabel: 'Browse Restaurants',
          onAction: () => context.goNamed(RouteNames.customerHome),
        ),
      );
    }

    return GlassScaffold(
      extendBodyBehindAppBar: false,
      appBar: TuishAppBar(
        title: AppStrings.cart,
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () async {
              final confirmed = await ConfirmationDialog.show(
                context,
                title: 'Clear Cart',
                message: 'Are you sure you want to remove all items?',
                confirmLabel: 'Clear',
                cancelLabel: AppStrings.cancel,
              );
              if (confirmed == true) {
                cartNotifier.clear();
              }
            },
            child: Text(
              'Clear',
              style: AppTypography.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          // Restaurant name
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s16,
              vertical: AppSizes.s8,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.storefront,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSizes.s8),
                Text(
                  cart.restaurantName ?? 'Restaurant',
                  style: AppTypography.titleSmall,
                ),
              ],
            ),
          ),
          const Divider(),

          // Cart items
          ...cart.items.map(
            (item) => CartItemTile(
              item: item,
              onIncrement: () {
                cartNotifier.updateQuantity(item.uniqueKey, item.quantity + 1);
              },
              onDecrement: () {
                cartNotifier.updateQuantity(item.uniqueKey, item.quantity - 1);
              },
              onRemove: () {
                cartNotifier.removeItem(item.uniqueKey);
              },
            ),
          ),

          const SizedBox(height: AppSizes.s16),

          // Coupon
          Padding(
            padding: AppSizes.paddingHorizontalM,
            child: CouponInput(
              appliedCoupon: _appliedCoupon,
              onApply: (code) {
                // Simulate coupon apply - in production this would call the checkout provider
                setState(() {
                  _appliedCoupon = code;
                  _discount = cart.subtotal * 0.1; // 10% off for demo
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coupon applied!')),
                );
              },
              onRemove: () {
                setState(() {
                  _appliedCoupon = null;
                  _discount = 0;
                });
              },
            ),
          ),

          const SizedBox(height: AppSizes.s16),

          // Bill summary
          Padding(
            padding: AppSizes.paddingHorizontalM,
            child: CartSummary(subtotal: cart.subtotal, discount: _discount),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: AppSizes.paddingAllM,
          child: TuishButton.primary(
            label:
                '${AppStrings.checkout} - \u20B9${(cart.subtotal + 40 + cart.subtotal * 0.05 - _discount).toStringAsFixed(0)}',
            onPressed: () {
              if (_appliedCoupon != null && _discount > 0) {
                ref.read(checkoutNotifierProvider.notifier)
                  ..removeCoupon()
                  // Set the pre-calculated discount directly so checkout
                  // reflects what the user already saw in the cart.
                  ..setDiscount(_discount, couponCode: _appliedCoupon);
              }
              context.pushNamed(RouteNames.checkout);
            },
          ),
        ),
      ),
    );
  }
}
