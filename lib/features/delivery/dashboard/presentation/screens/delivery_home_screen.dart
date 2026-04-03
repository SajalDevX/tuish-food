import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/utils/formatters.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/core/widgets/glass_scaffold.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_card.dart';
import 'package:tuish_food/features/delivery/dashboard/presentation/providers/delivery_dashboard_provider.dart';
import 'package:tuish_food/features/delivery/profile/presentation/widgets/online_toggle.dart';
import 'package:tuish_food/routing/route_paths.dart';

class DeliveryHomeScreen extends ConsumerWidget {
  const DeliveryHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final activeDelivery = ref.watch(activeDeliveryProvider);
    final availableOrders = ref.watch(availableOrdersProvider);
    final deliveryHistory = ref.watch(deliveryHistoryProvider);

    return GlassScaffold(
      appBar: TuishAppBar(
        title: AppStrings.appName,
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.secondary,
        onRefresh: () async {
          ref.invalidate(activeDeliveryProvider);
          ref.invalidate(availableOrdersProvider);
          ref.invalidate(deliveryHistoryProvider);
        },
        child: ListView(
          padding: AppSizes.screenPadding,
          children: [
            // Online / Offline toggle
            const OnlineToggle(),
            const SizedBox(height: AppSizes.s16),

            // Active delivery card
            activeDelivery.when(
              data: (order) {
                if (order == null) return const SizedBox.shrink();
                return _ActiveDeliveryCard(
                  restaurantName: order.restaurantName,
                  customerName: order.customerName,
                  status: order.status.displayName,
                  onTap: () => context.go(
                    '/delivery/orders/${order.orderId}',
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.s16),
                  child: CircularProgressIndicator(
                    color: AppColors.secondary,
                  ),
                ),
              ),
              error: (e, _) => const SizedBox.shrink(),
            ),

            // Quick stats
            const SizedBox(height: AppSizes.s16),
            Text('Quick Stats', style: AppTypography.titleMedium),
            const SizedBox(height: AppSizes.s12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.delivery_dining,
                    label: "Today's Deliveries",
                    value: deliveryHistory.when(
                      data: (orders) {
                        final today = DateTime.now();
                        final todayOrders = orders.where((o) =>
                            o.createdAt.year == today.year &&
                            o.createdAt.month == today.month &&
                            o.createdAt.day == today.day);
                        return '${todayOrders.length}';
                      },
                      loading: () => '-',
                      error: (_, _) => '0',
                    ),
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: AppSizes.s12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.star_outline,
                    label: 'Rating',
                    value: '4.8',
                    color: AppColors.starFilled,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s24),

            // Available orders count
            if (isOnline)
              availableOrders.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return const EmptyStateWidget(
                      message: 'No available orders right now.\nStay online to receive new orders.',
                      icon: Icons.delivery_dining_outlined,
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppStrings.availableOrders} (${orders.length})',
                            style: AppTypography.titleMedium,
                          ),
                          TextButton(
                            onPressed: () =>
                                context.go(RoutePaths.deliveryOrders),
                            child: Text(
                              AppStrings.seeAll,
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.s8),
                      // Show first 3 orders as preview
                      ...orders.take(3).map(
                            (order) => _OrderPreviewTile(
                              restaurantName: order.restaurantName,
                              distance: Formatters.formatDistance(
                                  order.distanceKm),
                              earnings: Formatters.formatCurrency(
                                  order.deliveryFee),
                              onTap: () => context.go(
                                '/delivery/orders/${order.orderId}',
                              ),
                            ),
                          ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.secondary,
                  ),
                ),
                error: (e, _) => EmptyStateWidget(
                  message: 'Failed to load orders',
                  icon: Icons.error_outline,
                  actionLabel: AppStrings.retry,
                  onAction: () => ref.invalidate(availableOrdersProvider),
                ),
              ),

            if (!isOnline)
              const EmptyStateWidget(
                message: 'You are offline.\nGo online to start receiving delivery requests.',
                icon: Icons.wifi_off_outlined,
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _ActiveDeliveryCard extends StatelessWidget {
  const _ActiveDeliveryCard({
    required this.restaurantName,
    required this.customerName,
    required this.status,
    required this.onTap,
  });

  final String restaurantName;
  final String customerName;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TuishCard(
      onTap: onTap,
      color: AppColors.secondary.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s8),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: AppSizes.borderRadiusS,
                ),
                child: const Icon(
                  Icons.delivery_dining,
                  color: Colors.white,
                  size: AppSizes.iconM,
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.activeDelivery,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                    Text(status, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s12),
          _MiniInfoRow(
            icon: Icons.restaurant_outlined,
            text: restaurantName,
          ),
          const SizedBox(height: AppSizes.s4),
          _MiniInfoRow(
            icon: Icons.person_outline,
            text: customerName,
          ),
        ],
      ),
    );
  }
}

class _MiniInfoRow extends StatelessWidget {
  const _MiniInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconS, color: AppColors.textSecondary),
        const SizedBox(width: AppSizes.s8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TuishCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: AppSizes.iconL),
          const SizedBox(height: AppSizes.s8),
          Text(value, style: AppTypography.headlineSmall),
          const SizedBox(height: AppSizes.s4),
          Text(
            label,
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OrderPreviewTile extends StatelessWidget {
  const _OrderPreviewTile({
    required this.restaurantName,
    required this.distance,
    required this.earnings,
    required this.onTap,
  });

  final String restaurantName;
  final String distance;
  final String earnings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TuishCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSizes.s8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s12,
        vertical: AppSizes.s12,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.s8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: AppSizes.borderRadiusS,
            ),
            child: const Icon(
              Icons.restaurant_outlined,
              color: AppColors.secondary,
              size: AppSizes.iconS,
            ),
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Text(
              restaurantName,
              style: AppTypography.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(earnings, style: AppTypography.priceSmall),
              Text(distance, style: AppTypography.bodySmall),
            ],
          ),
          const SizedBox(width: AppSizes.s4),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textHint,
          ),
        ],
      ),
    );
  }
}
