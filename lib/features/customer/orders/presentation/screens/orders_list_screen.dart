import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/features/customer/orders/presentation/providers/order_provider.dart';
import 'package:tuish_food/features/customer/orders/presentation/widgets/order_card.dart';
import 'package:tuish_food/injection_container.dart';

class OrdersListScreen extends ConsumerWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.uid ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: TuishAppBar(
          title: AppStrings.myOrders,
          showBackButton: false,
        ),
        body: Column(
          children: [
            // Tab bar
            Container(
              color: AppColors.surface,
              child: TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTypography.titleSmall,
                unselectedLabelStyle: AppTypography.bodyMedium,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Past'),
                ],
              ),
            ),

            // Tab views
            Expanded(
              child: TabBarView(
                children: [
                  _OrdersTab(
                    provider: activeOrdersProvider(userId),
                    emptyMessage: 'No active orders',
                    emptyIcon: Icons.receipt_long_outlined,
                  ),
                  _OrdersTab(
                    provider: pastOrdersProvider(userId),
                    emptyMessage: 'No past orders yet',
                    emptyIcon: Icons.history_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab({
    required this.provider,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  final FutureProvider provider;
  final String emptyMessage;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(provider);

    return ordersAsync.when(
      data: (orders) {
        final ordersList = orders as List;
        if (ordersList.isEmpty) {
          return EmptyStateWidget(
            message: emptyMessage,
            icon: emptyIcon,
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(provider);
          },
          child: ListView.builder(
            padding: AppSizes.paddingAllM,
            itemCount: ordersList.length,
            itemBuilder: (context, index) {
              return OrderCard(order: ordersList[index]);
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: AppSizes.iconXL,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.s16),
            Text(
              error.toString(),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.s16),
            TextButton(
              onPressed: () => ref.invalidate(provider),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}
