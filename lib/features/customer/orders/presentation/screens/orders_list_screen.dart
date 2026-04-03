import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/core/widgets/glass_scaffold.dart';
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
    final ordersAsync = ref.watch(customerOrdersProvider(userId));

    return GlassScaffold(
      appBar: const TuishAppBar(
        title: AppStrings.myOrders,
        showBackButton: false,
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const EmptyStateWidget(
              message: 'No orders yet',
              icon: Icons.receipt_long_outlined,
            );
          }

          final activeOrders = orders.where((order) => order.isActive).toList();
          final pastOrders = orders.where((order) => order.isTerminal).toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(customerOrdersProvider(userId));
            },
            child: ListView(
              padding: AppSizes.paddingAllM,
              children: [
                if (activeOrders.isNotEmpty) ...[
                  const _OrdersSectionHeader(
                    title: 'Current Orders',
                    subtitle: 'Track what is being prepared or delivered',
                  ),
                  const SizedBox(height: AppSizes.s12),
                  ...activeOrders.map((order) => OrderCard(order: order)),
                ],
                if (pastOrders.isNotEmpty) ...[
                  if (activeOrders.isNotEmpty)
                    const SizedBox(height: AppSizes.s12),
                  const _OrdersSectionHeader(
                    title: 'Past Orders',
                    subtitle: 'Your delivered and completed orders',
                  ),
                  const SizedBox(height: AppSizes.s12),
                  ...pastOrders.map((order) => OrderCard(order: order)),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
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
                onPressed: () => ref.invalidate(customerOrdersProvider(userId)),
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersSectionHeader extends StatelessWidget {
  const _OrdersSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.titleLarge),
        const SizedBox(height: AppSizes.s4),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
