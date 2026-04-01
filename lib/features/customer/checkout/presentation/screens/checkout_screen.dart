import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/loading_overlay.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/features/customer/cart/presentation/providers/cart_provider.dart';
import 'package:tuish_food/features/customer/cart/presentation/widgets/cart_summary.dart';
import 'package:tuish_food/features/customer/checkout/domain/entities/payment.dart';
import 'package:tuish_food/features/customer/checkout/domain/repositories/checkout_repository.dart';
import 'package:tuish_food/features/customer/checkout/presentation/providers/checkout_provider.dart';
import 'package:tuish_food/features/customer/checkout/presentation/widgets/delivery_address_card.dart';
import 'package:tuish_food/features/customer/checkout/presentation/widgets/order_summary_card.dart';
import 'package:tuish_food/features/customer/checkout/presentation/widgets/payment_method_tile.dart';
import 'package:tuish_food/features/customer/checkout/presentation/widgets/tip_selector.dart';
import 'package:tuish_food/routing/route_names.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartNotifierProvider);
    final checkoutState = ref.watch(checkoutNotifierProvider);
    final checkoutNotifier = ref.read(checkoutNotifierProvider.notifier);

    final deliveryFee = 40.0;
    final taxRate = 0.05;
    final taxes = cart.subtotal * taxRate;
    final total =
        cart.subtotal +
        deliveryFee +
        taxes +
        checkoutState.tip -
        checkoutState.discount;

    return LoadingOverlay(
      isLoading: checkoutState.isPlacingOrder,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.checkout),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // Order summary
            Padding(
              padding: AppSizes.paddingAllM,
              child: OrderSummaryCard(
                items: cart.items,
                restaurantName: cart.restaurantName ?? 'Restaurant',
              ),
            ),

            // Delivery address
            Padding(
              padding: AppSizes.paddingHorizontalM,
              child: DeliveryAddressCard(
                address: checkoutState.deliveryAddress,
                onChangePressed: () {
                  context.pushNamed(RouteNames.checkoutAddress);
                },
              ),
            ),
            const SizedBox(height: AppSizes.s16),

            // Payment method
            Padding(
              padding: AppSizes.paddingHorizontalM,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Method', style: AppTypography.titleSmall),
                  const SizedBox(height: AppSizes.s12),
                  PaymentMethodTile(
                    method: PaymentMethod.cashOnDelivery,
                    isSelected:
                        checkoutState.paymentMethod ==
                        PaymentMethod.cashOnDelivery,
                    onTap: () => checkoutNotifier.setPaymentMethod(
                      PaymentMethod.cashOnDelivery,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s8),
                  PaymentMethodTile(
                    method: PaymentMethod.card,
                    isSelected:
                        checkoutState.paymentMethod == PaymentMethod.card,
                    onTap: () =>
                        checkoutNotifier.setPaymentMethod(PaymentMethod.card),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.s16),

            // Tip
            Padding(
              padding: AppSizes.paddingHorizontalM,
              child: TipSelector(
                selectedTip: checkoutState.tip,
                onTipChanged: (tip) => checkoutNotifier.setTip(tip),
              ),
            ),
            const SizedBox(height: AppSizes.s16),

            // Special instructions
            Padding(
              padding: AppSizes.paddingHorizontalM,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Any special instructions?',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  prefixIcon: const Icon(
                    Icons.edit_note,
                    color: AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppSizes.borderRadiusM,
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppSizes.borderRadiusM,
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
                maxLines: 2,
                onChanged: (value) =>
                    checkoutNotifier.setSpecialInstructions(value),
              ),
            ),
            const SizedBox(height: AppSizes.s16),

            // Bill details
            Padding(
              padding: AppSizes.paddingHorizontalM,
              child: CartSummary(
                subtotal: cart.subtotal,
                deliveryFee: deliveryFee,
                taxRate: taxRate,
                tip: checkoutState.tip,
                discount: checkoutState.discount,
              ),
            ),

            // Error message
            if (checkoutState.errorMessage != null) ...[
              const SizedBox(height: AppSizes.s12),
              Padding(
                padding: AppSizes.paddingHorizontalM,
                child: Text(
                  checkoutState.errorMessage!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: AppSizes.paddingAllM,
            child: TuishButton.primary(
              label:
                  '${AppStrings.placeOrder} - \u20B9${total.toStringAsFixed(0)}',
              isLoading: checkoutState.isPlacingOrder,
              onPressed: checkoutState.deliveryAddress == null
                  ? null
                  : () async {
                      final params = PlaceOrderParams(
                        restaurantId: cart.restaurantId ?? '',
                        restaurantName: cart.restaurantName ?? 'Restaurant',
                        items: cart.items
                            .map(
                              (item) => OrderItemParam(
                                menuItemId: item.menuItemId,
                                name: item.name,
                                price: item.price,
                                quantity: item.quantity,
                                selectedCustomizations:
                                    item.selectedCustomizations,
                              ),
                            )
                            .toList(),
                        deliveryAddressId:
                            checkoutState.deliveryAddressId ?? '',
                        deliveryAddress: checkoutState.deliveryAddress ?? '',
                        paymentMethod: checkoutState.paymentMethod,
                        subtotal: cart.subtotal,
                        deliveryFee: deliveryFee,
                        taxes: taxes,
                        tip: checkoutState.tip,
                        discount: checkoutState.discount,
                        total: total,
                        couponCode: checkoutState.couponCode,
                        specialInstructions: checkoutState.specialInstructions,
                      );

                      final orderId = await checkoutNotifier.placeOrder(params);

                      if (orderId != null && context.mounted) {
                        // Clear cart
                        ref.read(cartNotifierProvider.notifier).clear();
                        // Reset checkout state
                        checkoutNotifier.reset();
                        // Navigate to confirmation
                        context.goNamed(
                          RouteNames.orderConfirmation,
                          pathParameters: {'orderId': orderId},
                        );
                      }
                    },
            ),
          ),
        ),
      ),
    );
  }
}
