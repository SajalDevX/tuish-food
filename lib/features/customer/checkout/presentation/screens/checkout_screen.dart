import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/core/widgets/glass_scaffold.dart';
import 'package:tuish_food/core/widgets/loading_overlay.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/features/customer/cart/presentation/providers/cart_provider.dart';
import 'package:tuish_food/features/customer/checkout/domain/entities/checkout_order_draft.dart';
import 'package:tuish_food/features/customer/cart/presentation/widgets/cart_summary.dart';
import 'package:tuish_food/features/customer/checkout/domain/entities/payment.dart';
import 'package:tuish_food/features/customer/checkout/domain/repositories/checkout_repository.dart';
import 'package:tuish_food/features/customer/checkout/presentation/providers/checkout_provider.dart';
import 'package:tuish_food/features/customer/checkout/presentation/widgets/delivery_address_card.dart';
import 'package:tuish_food/features/customer/checkout/presentation/widgets/order_summary_card.dart';
import 'package:tuish_food/features/customer/checkout/presentation/widgets/payment_method_tile.dart';
import 'package:tuish_food/features/customer/checkout/presentation/widgets/tip_selector.dart';
import 'package:tuish_food/routing/route_names.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, this.orderDraft});

  final CheckoutOrderDraft? orderDraft;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late final Razorpay _razorpay;
  PlaceOrderParams? _pendingOrderParams;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final checkoutNotifier = ref.read(checkoutNotifierProvider.notifier);

    if (response.orderId == null ||
        response.paymentId == null ||
        response.signature == null) {
      _showError('Payment verification failed: missing data');
      return;
    }

    // Build order data from the pending params
    final params = _pendingOrderParams;
    if (params == null) {
      _showError('Order data lost. Please try again.');
      return;
    }

    final orderData = {
      'restaurantId': params.restaurantId,
      'restaurantName': params.restaurantName,
      'items': params.items
          .map(
            (i) => {
              'id': i.menuItemId,
              'name': i.name,
              'price': i.price,
              'quantity': i.quantity,
              'totalPrice': i.price * i.quantity,
            },
          )
          .toList(),
      'deliveryAddressId': params.deliveryAddressId,
      'deliveryAddress': params.deliveryAddress,
      'paymentMethod': 'razorpay',
      'subtotal': params.subtotal,
      'deliveryFee': params.deliveryFee,
      'tax': params.taxes,
      'tip': params.tip,
      'discount': params.discount,
      'totalAmount': params.total,
      if (params.couponCode != null) 'couponCode': params.couponCode,
      if (params.specialInstructions != null)
        'specialInstructions': params.specialInstructions,
    };

    final orderId = await checkoutNotifier.verifyAndPlaceOrder(
      razorpayOrderId: response.orderId!,
      paymentId: response.paymentId!,
      signature: response.signature!,
      orderData: orderData,
    );

    if (orderId != null && mounted) {
      if (widget.orderDraft == null) {
        ref.read(cartNotifierProvider.notifier).clear();
      }
      checkoutNotifier.reset();
      context.goNamed(
        RouteNames.orderConfirmation,
        pathParameters: {'orderId': orderId},
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final message = response.message ?? 'Payment failed';
    _showError(message);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Redirecting to ${response.walletName}...')),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _onPlaceOrder() async {
    final cart = ref.read(cartNotifierProvider);
    final checkoutState = ref.read(checkoutNotifierProvider);
    final checkoutNotifier = ref.read(checkoutNotifierProvider.notifier);
    final orderItems = widget.orderDraft?.items ?? cart.items;
    final restaurantId =
        widget.orderDraft?.restaurantId ?? cart.restaurantId ?? '';
    final restaurantName =
        widget.orderDraft?.restaurantName ??
        cart.restaurantName ??
        'Restaurant';
    final subtotal = widget.orderDraft?.subtotal ?? cart.subtotal;

    const deliveryFee = 40.0;
    const taxRate = 0.05;
    final taxes = subtotal * taxRate;
    final total =
        subtotal +
        deliveryFee +
        taxes +
        checkoutState.tip -
        checkoutState.discount;

    final params = PlaceOrderParams(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      items: orderItems
          .map(
            (item) => OrderItemParam(
              menuItemId: item.menuItemId,
              name: item.name,
              price: item.price,
              quantity: item.quantity,
              selectedCustomizations: item.selectedCustomizations,
            ),
          )
          .toList(),
      deliveryAddressId: checkoutState.deliveryAddressId ?? '',
      deliveryAddress: checkoutState.deliveryAddress ?? '',
      paymentMethod: checkoutState.paymentMethod,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      taxes: taxes,
      tip: checkoutState.tip,
      discount: checkoutState.discount,
      total: total,
      couponCode: checkoutState.couponCode,
      specialInstructions: checkoutState.specialInstructions,
    );

    if (checkoutState.paymentMethod == PaymentMethod.cashOnDelivery) {
      // COD: place order directly
      final orderId = await checkoutNotifier.placeOrder(params);
      if (orderId != null && mounted) {
        if (widget.orderDraft == null) {
          ref.read(cartNotifierProvider.notifier).clear();
        }
        checkoutNotifier.reset();
        context.goNamed(
          RouteNames.orderConfirmation,
          pathParameters: {'orderId': orderId},
        );
      }
    } else {
      // Razorpay: create server-side order, then open checkout
      _pendingOrderParams = params;
      final razorpayOrderId = await checkoutNotifier.createRazorpayOrder(
        amount: total,
        receipt: '${restaurantId}_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (razorpayOrderId == null) return;

      const razorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID');
      if (razorpayKeyId.isEmpty) {
        _showError('Payment is not configured. Please contact support.');
        return;
      }

      final options = {
        'key': razorpayKeyId,
        'amount': (total * 100).toInt(), // amount in paise
        'currency': 'INR',
        'name': 'Tuish Food',
        'description': 'Order from $restaurantName',
        'order_id': razorpayOrderId,
        'prefill': {
          'email': '', // populated from user profile if available
        },
        'theme': {'color': '#FF6B35'},
        'retry': {'enabled': true, 'max_count': 3},
      };

      _razorpay.open(options);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartNotifierProvider);
    final checkoutState = ref.watch(checkoutNotifierProvider);
    final checkoutNotifier = ref.read(checkoutNotifierProvider.notifier);
    final orderItems = widget.orderDraft?.items ?? cart.items;
    final restaurantName =
        widget.orderDraft?.restaurantName ??
        cart.restaurantName ??
        'Restaurant';
    final subtotal = widget.orderDraft?.subtotal ?? cart.subtotal;

    const deliveryFee = 40.0;
    const taxRate = 0.05;
    final taxes = subtotal * taxRate;
    final total =
        subtotal +
        deliveryFee +
        taxes +
        checkoutState.tip -
        checkoutState.discount;

    if (orderItems.isEmpty) {
      return const GlassScaffold(
        appBar: TuishAppBar(title: AppStrings.checkout),
        body: EmptyStateWidget(
          message: 'No items selected for checkout',
          icon: Icons.shopping_bag_outlined,
        ),
      );
    }

    return LoadingOverlay(
      isLoading: checkoutState.isPlacingOrder,
      child: GlassScaffold(
        appBar: TuishAppBar(title: AppStrings.checkout),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // Order summary
            Padding(
              padding: AppSizes.paddingAllM,
              child: OrderSummaryCard(
                items: orderItems,
                restaurantName: restaurantName,
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
                  Text(
                    'Payment Method',
                    style: AppTypography.titleSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s12),
                  PaymentMethodTile(
                    method: PaymentMethod.razorpay,
                    isSelected:
                        checkoutState.paymentMethod == PaymentMethod.razorpay,
                    onTap: () => checkoutNotifier.setPaymentMethod(
                      PaymentMethod.razorpay,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s8),
                  PaymentMethodTile(
                    method: PaymentMethod.cashOnDelivery,
                    isSelected:
                        checkoutState.paymentMethod ==
                        PaymentMethod.cashOnDelivery,
                    onTap: () => checkoutNotifier.setPaymentMethod(
                      PaymentMethod.cashOnDelivery,
                    ),
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
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Any special instructions?',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: Colors.white38,
                  ),
                  prefixIcon: const Icon(
                    Icons.edit_note,
                    color: Colors.white54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppSizes.borderRadiusM,
                    borderSide: const BorderSide(
                      color: AppColors.darkGlassBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppSizes.borderRadiusM,
                    borderSide: const BorderSide(
                      color: AppColors.darkGlassBorder,
                    ),
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
                subtotal: subtotal,
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
                  : _onPlaceOrder,
            ),
          ),
        ),
      ),
    );
  }
}
