import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/utils/formatters.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/features/delivery/dashboard/domain/entities/delivery_order.dart';

/// Bottom sheet showing order details with a 30-second countdown timer
/// for accept/reject actions.
class OrderAcceptSheet extends StatefulWidget {
  const OrderAcceptSheet({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onReject,
  });

  final DeliveryOrder order;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  /// Shows the [OrderAcceptSheet] as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required DeliveryOrder order,
    required VoidCallback onAccept,
    required VoidCallback onReject,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXL),
        ),
      ),
      builder: (_) => OrderAcceptSheet(
        order: order,
        onAccept: onAccept,
        onReject: onReject,
      ),
    );
  }

  @override
  State<OrderAcceptSheet> createState() => _OrderAcceptSheetState();
}

class _OrderAcceptSheetState extends State<OrderAcceptSheet> {
  static const int _countdownSeconds = 30;
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = _countdownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        _timer?.cancel();
        widget.onReject();
        if (mounted) Navigator.of(context).pop();
        return;
      }
      setState(() => _remaining--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final progress = _remaining / _countdownSeconds;

    return SafeArea(
      child: Padding(
        padding: AppSizes.paddingAllM,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: AppSizes.borderRadiusPill,
              ),
            ),
            const SizedBox(height: AppSizes.s16),

            // Countdown timer
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _remaining <= 10 ? AppColors.error : AppColors.secondary,
                    ),
                  ),
                ),
                Text(
                  '$_remaining',
                  style: AppTypography.headlineSmall.copyWith(
                    color: _remaining <= 10
                        ? AppColors.error
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s16),

            Text(
              'New Delivery Request',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: AppSizes.s16),

            // Restaurant info
            _DetailRow(
              icon: Icons.restaurant_outlined,
              title: order.restaurantName,
              subtitle: order.restaurantAddress,
            ),
            const SizedBox(height: AppSizes.s12),

            // Customer info
            _DetailRow(
              icon: Icons.person_outline,
              title: order.customerName,
              subtitle: order.customerAddress,
            ),
            const SizedBox(height: AppSizes.s16),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  label: 'Distance',
                  value: Formatters.formatDistance(order.distanceKm),
                ),
                _StatItem(
                  label: 'Earnings',
                  value: Formatters.formatCurrency(order.deliveryFee),
                ),
                _StatItem(
                  label: 'Items',
                  value: '${order.itemsCount}',
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TuishButton.outlined(
                    label: AppStrings.rejectOrder,
                    onPressed: () {
                      _timer?.cancel();
                      widget.onReject();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.s12),
                Expanded(
                  child: TuishButton.primary(
                    label: AppStrings.acceptOrder,
                    onPressed: () {
                      _timer?.cancel();
                      widget.onAccept();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s8),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.s8),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: AppSizes.borderRadiusS,
          ),
          child: Icon(icon, color: AppColors.secondary, size: AppSizes.iconM),
        ),
        const SizedBox(width: AppSizes.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleSmall),
              Text(
                subtitle,
                style: AppTypography.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.titleMedium),
        const SizedBox(height: AppSizes.s4),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }
}
