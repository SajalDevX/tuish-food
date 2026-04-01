import 'package:flutter/material.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/extensions/datetime_extensions.dart';
import 'package:tuish_food/features/customer/orders/domain/entities/order.dart';

class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({
    super.key,
    required this.currentStatus,
    required this.statusHistory,
  });

  final OrderStatus currentStatus;
  final List<StatusHistoryEntry> statusHistory;

  static const List<OrderStatus> _normalFlow = [
    OrderStatus.placed,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.readyForPickup,
    OrderStatus.pickedUp,
    OrderStatus.onTheWay,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final steps = currentStatus == OrderStatus.cancelled
        ? [..._getCompletedStatuses(), OrderStatus.cancelled]
        : _normalFlow;

    return Column(
      children: List.generate(steps.length, (index) {
        final status = steps[index];
        final isCompleted = _isStatusCompleted(status);
        final isCurrent = status == currentStatus;
        final isLast = index == steps.length - 1;
        final historyEntry = _getHistoryEntry(status);

        return _TimelineStep(
          status: status,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          isLast: isLast,
          timestamp: historyEntry?.timestamp,
          note: historyEntry?.note,
        );
      }),
    );
  }

  List<OrderStatus> _getCompletedStatuses() {
    return statusHistory
        .where((e) => e.status != OrderStatus.cancelled)
        .map((e) => e.status)
        .toList();
  }

  bool _isStatusCompleted(OrderStatus status) {
    if (status == OrderStatus.cancelled) {
      return currentStatus == OrderStatus.cancelled;
    }
    final currentIndex = _normalFlow.indexOf(currentStatus);
    final statusIndex = _normalFlow.indexOf(status);
    if (currentIndex == -1 || statusIndex == -1) return false;
    return statusIndex <= currentIndex;
  }

  StatusHistoryEntry? _getHistoryEntry(OrderStatus status) {
    try {
      return statusHistory.firstWhere((e) => e.status == status);
    } catch (_) {
      return null;
    }
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.status,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
    this.timestamp,
    this.note,
  });

  final OrderStatus status;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;
  final DateTime? timestamp;
  final String? note;

  Color get _dotColor {
    if (status == OrderStatus.cancelled) return AppColors.statusCancelled;
    if (isCompleted || isCurrent) return AppColors.success;
    return AppColors.divider;
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: isCurrent ? 20 : 16,
                  height: isCurrent ? 20 : 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _dotColor,
                    border: isCurrent
                        ? Border.all(
                            color: _dotColor.withValues(alpha: 0.3),
                            width: 3,
                          )
                        : null,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? AppColors.success : AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: AppSizes.s12),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppSizes.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.displayName,
                    style: (isCurrent
                            ? AppTypography.titleSmall
                            : AppTypography.bodyMedium)
                        .copyWith(
                      color: isCompleted || isCurrent
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                      fontWeight:
                          isCurrent ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      timestamp!.formattedDateTime,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (note != null && note!.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      note!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
