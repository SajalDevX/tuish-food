import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/widgets/status_badge.dart';

class RecentOrdersTable extends StatelessWidget {
  const RecentOrdersTable({
    super.key,
    required this.orders,
    this.onOrderTap,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> orders;
  final void Function(String orderId)? onOrderTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppSizes.borderRadiusM,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppSizes.paddingAllM,
            child: Row(
              children: [
                Text('Recent Orders', style: AppTypography.titleMedium),
                const Spacer(),
                Text(
                  '${orders.length} orders',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          if (orders.isEmpty)
            Padding(
              padding: AppSizes.paddingAllL,
              child: Center(
                child: Text(
                  'No recent orders',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  AppColors.background,
                ),
                headingTextStyle: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                dataTextStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
                columnSpacing: AppSizes.s24,
                horizontalMargin: AppSizes.s16,
                columns: const [
                  DataColumn(label: Text('Order #')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Restaurant')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Date')),
                ],
                rows: orders.map((doc) {
                  final data = doc.data();
                  final orderNumber =
                      data['orderNumber'] as String? ?? doc.id.substring(0, 8);
                  final customerName =
                      data['customerName'] as String? ?? 'Unknown';
                  final restaurantName =
                      data['restaurantName'] as String? ?? 'Unknown';
                  final amount =
                      (data['totalAmount'] as num?)?.toDouble() ?? 0;
                  final statusStr = data['status'] as String? ?? 'placed';
                  final status = OrderStatus.fromString(statusStr);
                  final createdAt = data['createdAt'] != null
                      ? (data['createdAt'] as Timestamp).toDate()
                      : DateTime.now();

                  return DataRow(
                    onSelectChanged: onOrderTap != null
                        ? (_) => onOrderTap!(doc.id)
                        : null,
                    cells: [
                      DataCell(
                        Text(
                          '#$orderNumber',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DataCell(Text(customerName)),
                      DataCell(Text(restaurantName)),
                      DataCell(
                        Text(
                          '\$${amount.toStringAsFixed(2)}',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DataCell(StatusBadge(status: status)),
                      DataCell(
                        Text(
                          DateFormat('MMM dd, hh:mm a').format(createdAt),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
