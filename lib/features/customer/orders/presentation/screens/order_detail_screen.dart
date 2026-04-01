import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/extensions/datetime_extensions.dart';
import 'package:tuish_food/core/widgets/confirmation_dialog.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/features/customer/orders/domain/entities/order.dart';
import 'package:tuish_food/features/customer/orders/presentation/providers/order_provider.dart';
import 'package:tuish_food/features/customer/orders/presentation/widgets/order_items_list.dart';
import 'package:tuish_food/features/customer/orders/presentation/widgets/order_status_timeline.dart';
import 'package:tuish_food/routing/route_names.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(watchOrderProvider(widget.orderId));

    return Scaffold(
      appBar: const TuishAppBar(title: 'Order Details'),
      body: orderAsync.when(
        data: (order) => _buildContent(context, order),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: AppSizes.iconXL, color: AppColors.error),
              const SizedBox(height: AppSizes.s16),
              Text(error.toString(),
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSizes.s16),
              TextButton(
                onPressed: () =>
                    ref.invalidate(watchOrderProvider(widget.orderId)),
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CustomerOrder order) {
    return SingleChildScrollView(
      padding: AppSizes.paddingAllM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          _buildOrderHeader(order),

          const SizedBox(height: AppSizes.s24),

          // Status timeline
          Text('Order Status', style: AppTypography.titleMedium),
          const SizedBox(height: AppSizes.s16),
          OrderStatusTimeline(
            currentStatus: order.status,
            statusHistory: order.statusHistory,
          ),

          const SizedBox(height: AppSizes.s24),

          // Items list
          OrderItemsList(items: order.items),

          const SizedBox(height: AppSizes.s24),

          // Price breakdown
          _buildPriceBreakdown(order),

          const SizedBox(height: AppSizes.s24),

          // Delivery info
          if (order.deliveryAddress != null) ...[
            _buildDeliveryInfo(order),
            const SizedBox(height: AppSizes.s24),
          ],

          // Actions
          _buildActions(context, order),

          const SizedBox(height: AppSizes.s32),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(CustomerOrder order) {
    return Container(
      padding: AppSizes.paddingAllM,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppSizes.borderRadiusM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.orderNumber}',
                style: AppTypography.titleMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s12,
                  vertical: AppSizes.s4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(order.status),
                  borderRadius: AppSizes.borderRadiusPill,
                ),
                child: Text(
                  order.status.displayName,
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s8),
          Text(
            'From: ${order.restaurantName ?? 'Restaurant'}',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          Text(
            'Placed: ${order.createdAt.formattedDateTime}',
            style: AppTypography.bodySmall,
          ),
          if (order.estimatedDeliveryTime != null) ...[
            const SizedBox(height: AppSizes.s4),
            Text(
              'Estimated Delivery: ${order.estimatedDeliveryTime!.formattedTime}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(CustomerOrder order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price Breakdown', style: AppTypography.titleMedium),
        const SizedBox(height: AppSizes.s12),
        _priceRow('Subtotal', order.subtotal),
        _priceRow('Delivery Fee', order.deliveryFee),
        _priceRow('Service Fee', order.serviceFee),
        _priceRow('Tax', order.tax),
        if (order.tip > 0) _priceRow('Tip', order.tip),
        if (order.discount > 0)
          _priceRow('Discount', -order.discount, isDiscount: true),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSizes.s8),
          child: Divider(color: AppColors.divider),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: AppTypography.titleMedium),
            Text(
              '\u20B9${order.totalAmount.toStringAsFixed(2)}',
              style: AppTypography.price,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.s8),
        Row(
          children: [
            Icon(Icons.payment, size: AppSizes.iconS, color: AppColors.textSecondary),
            const SizedBox(width: AppSizes.s8),
            Text(
              '${order.paymentMethod} - ${order.paymentStatus.displayName}',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _priceRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '${isDiscount ? "-" : ""}\u20B9${amount.abs().toStringAsFixed(2)}',
            style: AppTypography.bodyMedium.copyWith(
              color: isDiscount ? AppColors.success : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(CustomerOrder order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Delivery Address', style: AppTypography.titleMedium),
        const SizedBox(height: AppSizes.s8),
        Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: AppSizes.iconM, color: AppColors.primary),
            const SizedBox(width: AppSizes.s8),
            Expanded(
              child: Text(
                order.deliveryAddress!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        if (order.deliveryPartnerName != null) ...[
          const SizedBox(height: AppSizes.s12),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: AppSizes.iconM, color: AppColors.secondary),
              const SizedBox(width: AppSizes.s8),
              Text(
                'Driver: ${order.deliveryPartnerName}',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActions(BuildContext context, CustomerOrder order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Track order (active orders)
        if (order.isActive &&
            order.status != OrderStatus.placed &&
            order.deliveryPartnerId != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.s12),
            child: TuishButton.primary(
              label: AppStrings.trackOrder,
              icon: const Icon(Icons.delivery_dining,
                  color: AppColors.onPrimary, size: 20),
              onPressed: () {
                context.pushNamed(
                  RouteNames.orderTracking,
                  pathParameters: {'orderId': order.id},
                );
              },
            ),
          ),

        // Cancel order (only if placed or confirmed)
        if (order.status == OrderStatus.placed ||
            order.status == OrderStatus.confirmed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.s12),
            child: TuishButton.outlined(
              label: 'Cancel Order',
              isLoading: _isCancelling,
              onPressed: () => _handleCancelOrder(context, order),
            ),
          ),

        // Review (delivered orders)
        if (order.status == OrderStatus.delivered)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.s12),
            child: TuishButton.primary(
              label: AppStrings.rateOrder,
              icon: const Icon(Icons.star_outline,
                  color: AppColors.onPrimary, size: 20),
              onPressed: () {
                context.pushNamed(
                  RouteNames.orderReview,
                  pathParameters: {'orderId': order.id},
                );
              },
            ),
          ),

        // Reorder (terminal orders)
        if (order.isTerminal)
          TuishButton.secondary(
            label: AppStrings.reorder,
            icon: const Icon(Icons.replay,
                color: AppColors.onSecondary, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Items added to cart'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _handleCancelOrder(
      BuildContext context, CustomerOrder order) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Cancel Order',
      message:
          'Are you sure you want to cancel this order? This action cannot be undone.',
      confirmLabel: 'Yes, Cancel',
      cancelLabel: 'No, Keep Order',
    );

    if (confirmed == true && mounted) {
      setState(() => _isCancelling = true);
      try {
        final repository = ref.read(orderRepositoryProvider);
        final result = await repository.cancelOrder(
          order.id,
          'Cancelled by customer',
        );
        result.fold(
          (failure) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(failure.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order cancelled successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
        );
      } finally {
        if (mounted) setState(() => _isCancelling = false);
      }
    }
  }

  Color _statusColor(OrderStatus status) {
    return switch (status) {
      OrderStatus.placed => AppColors.statusPlaced,
      OrderStatus.confirmed => AppColors.statusConfirmed,
      OrderStatus.preparing => AppColors.statusPreparing,
      OrderStatus.readyForPickup => AppColors.statusReady,
      OrderStatus.pickedUp => AppColors.statusPickedUp,
      OrderStatus.onTheWay => AppColors.statusOnTheWay,
      OrderStatus.delivered => AppColors.statusDelivered,
      OrderStatus.cancelled => AppColors.statusCancelled,
    };
  }
}
