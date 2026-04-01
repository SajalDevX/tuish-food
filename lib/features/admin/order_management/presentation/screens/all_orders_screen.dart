import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/utils/formatters.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/core/widgets/status_badge.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_card.dart';
import 'package:tuish_food/features/admin/order_management/presentation/providers/order_management_provider.dart';
import 'package:tuish_food/features/admin/order_management/presentation/widgets/order_filter_bar.dart';

class AllOrdersScreen extends ConsumerWidget {
  const AllOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(filteredOrdersProvider);

    return Scaffold(
      appBar: const TuishAppBar(
        title: AppStrings.orders,
        showBackButton: false,
      ),
      body: Column(
        children: [
          // Filter bar
          const OrderFilterBar(),
          const SizedBox(height: AppSizes.s8),

          // Orders list
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => EmptyStateWidget(
                message: 'Failed to load orders',
                icon: Icons.error_outline,
                actionLabel: AppStrings.retry,
                onAction: () => ref.invalidate(allAdminOrdersProvider),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'No orders found',
                    icon: Icons.receipt_long_outlined,
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(allAdminOrdersProvider);
                  },
                  child: ListView.builder(
                    padding: AppSizes.screenPadding,
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final doc = orders[index];
                      final data = doc.data();
                      return _OrderCard(
                        orderId: doc.id,
                        data: data,
                        onTap: () =>
                            context.push('/admin/orders/${doc.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.orderId,
    required this.data,
    required this.onTap,
  });

  final String orderId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final orderNumber = Formatters.formatOrderNumber(orderId);
    final customerName =
        data['customerName'] as String? ?? 'Unknown Customer';
    final restaurantName =
        data['restaurantName'] as String? ?? 'Unknown Restaurant';
    final status = OrderStatus.fromString(
        data['status'] as String? ?? 'placed');
    final totalAmount =
        (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final dateFormat = DateFormat('MMM dd, yyyy');

    return TuishCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSizes.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order number and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(orderNumber, style: AppTypography.titleSmall),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: AppSizes.s12),

          // Customer
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: AppSizes.iconS, color: AppColors.textSecondary),
              const SizedBox(width: AppSizes.s8),
              Expanded(
                child: Text(
                  customerName,
                  style: AppTypography.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s4),

          // Restaurant
          Row(
            children: [
              const Icon(Icons.restaurant_outlined,
                  size: AppSizes.iconS, color: AppColors.textSecondary),
              const SizedBox(width: AppSizes.s8),
              Expanded(
                child: Text(
                  restaurantName,
                  style: AppTypography.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s12),

          // Amount and date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatters.formatCurrency(totalAmount),
                style: AppTypography.price,
              ),
              if (createdAt != null)
                Text(
                  dateFormat.format(createdAt),
                  style: AppTypography.bodySmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
