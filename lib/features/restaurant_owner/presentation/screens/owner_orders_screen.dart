import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/core/widgets/status_badge.dart';
import 'package:tuish_food/features/customer/orders/domain/entities/order.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/providers/restaurant_owner_provider.dart';
import 'package:tuish_food/routing/route_paths.dart';

class OwnerOrdersScreen extends ConsumerStatefulWidget {
  const OwnerOrdersScreen({super.key});

  @override
  ConsumerState<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends ConsumerState<OwnerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabStatuses = <OrderStatus?>[
    OrderStatus.placed,
    OrderStatus.preparing,
    OrderStatus.readyForPickup,
    null, // completed = delivered + cancelled
  ];
  static const _tabLabels = ['New', 'Preparing', 'Ready', 'Past'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(myRestaurantOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: _tabLabels.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading orders: $e')),
        data: (orders) {
          return TabBarView(
            controller: _tabController,
            children: _tabStatuses.map((status) {
              final filtered = status != null
                  ? orders.where((o) => o.status == status).toList()
                  : orders.where((o) => o.status.isTerminal).toList();

              if (filtered.isEmpty) {
                return const EmptyStateWidget(
                  message: 'No orders here',
                  icon: Icons.receipt_long_outlined,
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(myRestaurantOrdersProvider);
                },
                child: ListView.separated(
                  padding: AppSizes.screenPadding,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSizes.s8),
                  itemBuilder: (context, index) {
                    return _OrderCard(order: filtered[index]);
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppSizes.elevationCard,
      shape: RoundedRectangleBorder(borderRadius: AppSizes.borderRadiusM),
      child: InkWell(
        borderRadius: AppSizes.borderRadiusM,
        onTap: () {
          context.push(
            RoutePaths.restaurantOrderDetail
                .replaceFirst(':orderId', order.id),
          );
        },
        child: Padding(
          padding: AppSizes.paddingAllM,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber.isNotEmpty
                          ? order.orderNumber
                          : 'Order #${order.id.length >= 6 ? order.id.substring(0, 6).toUpperCase() : order.id.toUpperCase()}',
                      style: AppTypography.titleSmall,
                    ),
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      '${order.totalItemCount} items \u2022 \u20B9${order.totalAmount.toStringAsFixed(0)}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: order.status),
            ],
          ),
        ),
      ),
    );
  }
}
