import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/widgets/loading_overlay.dart';
import 'package:tuish_food/core/widgets/status_badge.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/features/customer/orders/domain/entities/order.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/providers/restaurant_owner_provider.dart';

class OwnerOrderDetailScreen extends ConsumerStatefulWidget {
  const OwnerOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OwnerOrderDetailScreen> createState() =>
      _OwnerOrderDetailScreenState();
}

class _OwnerOrderDetailScreenState
    extends ConsumerState<OwnerOrderDetailScreen> {
  bool _isUpdating = false;

  String _shortId(String id) =>
      id.length >= 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(myOrderDetailProvider(widget.orderId));

    return orderAsync.when(
      loading: () => Scaffold(
        appBar: TuishAppBar(title: 'Order #${_shortId(widget.orderId)}'),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: TuishAppBar(title: 'Order #${_shortId(widget.orderId)}'),
        body: Center(child: Text('Error: $e')),
      ),
      data: (order) {
        if (order == null) {
          return Scaffold(
            appBar: TuishAppBar(title: 'Order #${_shortId(widget.orderId)}'),
            body: const Center(child: Text('Order not found')),
          );
        }
        return _buildDetail(context, order);
      },
    );
  }

  Widget _buildDetail(BuildContext context, CustomerOrder order) {
    final displayId = order.orderNumber.isNotEmpty
        ? order.orderNumber
        : 'Order #${_shortId(order.id)}';

    return Scaffold(
      appBar: TuishAppBar(title: displayId),
      body: LoadingOverlay(
        isLoading: _isUpdating,
        child: ListView(
          padding: AppSizes.paddingAllL,
          children: [
            // Status
            Row(
              children: [
                Text('Status: ', style: AppTypography.labelLarge),
                StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: AppSizes.s16),

            // Items
            Text('Order Items', style: AppTypography.titleMedium),
            const SizedBox(height: AppSizes.s8),
            Card(
              child: Column(
                children: order.items.map((item) {
                  return ListTile(
                    title: Text(item.name, style: AppTypography.bodyLarge),
                    trailing: Text(
                      '${item.quantity}x  \u20B9${item.totalPrice.toStringAsFixed(0)}',
                      style: AppTypography.bodyMedium,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSizes.s16),

            // Delivery address
            if (order.deliveryAddress != null) ...[
              Text('Delivery Address', style: AppTypography.titleMedium),
              const SizedBox(height: AppSizes.s8),
              Card(
                child: Padding(
                  padding: AppSizes.paddingAllM,
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.primary),
                      const SizedBox(width: AppSizes.s12),
                      Expanded(
                        child: Text(order.deliveryAddress!,
                            style: AppTypography.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.s16),
            ],

            // Payment summary
            Text('Payment Summary', style: AppTypography.titleMedium),
            const SizedBox(height: AppSizes.s8),
            Card(
              child: Padding(
                padding: AppSizes.paddingAllM,
                child: Column(
                  children: [
                    _totalRow('Subtotal',
                        '\u20B9${order.subtotal.toStringAsFixed(0)}'),
                    _totalRow('Delivery Fee',
                        '\u20B9${order.deliveryFee.toStringAsFixed(0)}'),
                    _totalRow(
                        'Tax', '\u20B9${order.tax.toStringAsFixed(0)}'),
                    if (order.tip > 0)
                      _totalRow(
                          'Tip', '\u20B9${order.tip.toStringAsFixed(0)}'),
                    if (order.discount > 0)
                      _totalRow('Discount',
                          '-\u20B9${order.discount.toStringAsFixed(0)}'),
                    const Divider(),
                    _totalRow(
                      'Total',
                      '\u20B9${order.totalAmount.toStringAsFixed(0)}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.s32),

            // Action button
            if (!order.status.isTerminal)
              TuishButton.primary(
                label: _nextActionLabel(order.status),
                onPressed: _isUpdating
                    ? null
                    : () => _handleStatusUpdate(order),
                isLoading: _isUpdating,
              ),
            const SizedBox(height: AppSizes.s24),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  isBold ? AppTypography.titleSmall : AppTypography.bodyMedium),
          Text(value,
              style: isBold
                  ? AppTypography.titleSmall
                  : AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _nextActionLabel(OrderStatus status) {
    return switch (status) {
      OrderStatus.placed => 'Confirm Order',
      OrderStatus.confirmed => 'Start Preparing',
      OrderStatus.preparing => 'Mark Ready for Pickup',
      _ => 'Update Status',
    };
  }

  OrderStatus? _nextStatus(OrderStatus status) {
    return switch (status) {
      OrderStatus.placed => OrderStatus.confirmed,
      OrderStatus.confirmed => OrderStatus.preparing,
      OrderStatus.preparing => OrderStatus.readyForPickup,
      _ => null,
    };
  }

  Future<void> _handleStatusUpdate(CustomerOrder order) async {
    final next = _nextStatus(order.status);
    if (next == null) return;

    setState(() => _isUpdating = true);
    try {
      await updateOrderStatus(
        ref,
        orderId: order.id,
        newStatus: next.firestoreValue,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order updated to ${next.displayName}'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(myOrderDetailProvider(widget.orderId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }
}
