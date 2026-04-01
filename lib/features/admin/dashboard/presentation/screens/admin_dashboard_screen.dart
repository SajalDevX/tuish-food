import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/features/admin/dashboard/presentation/providers/admin_dashboard_provider.dart';
import 'package:tuish_food/features/admin/dashboard/presentation/widgets/recent_orders_table.dart';
import 'package:tuish_food/features/admin/dashboard/presentation/widgets/revenue_chart.dart';
import 'package:tuish_food/features/admin/dashboard/presentation/widgets/stats_card.dart';
import 'package:tuish_food/routing/route_paths.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardStatsProvider);
    final recentOrdersAsync = ref.watch(recentOrdersProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: TuishAppBar(
        title: 'Admin Dashboard',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(recentOrdersProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSizes.paddingAllM,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period selector
              _PeriodSelector(
                selectedPeriod: selectedPeriod,
                onPeriodChanged: (period) {
                  ref.read(selectedPeriodProvider.notifier).update(period);
                },
              ),
              const SizedBox(height: AppSizes.s16),

              // KPI Cards
              dashboardAsync.when(
                data: (stats) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatsCard(
                            icon: Icons.shopping_bag_rounded,
                            value: stats.totalOrders.toString(),
                            label: 'Total Orders',
                            trend: '+12%',
                            trendPositive: true,
                            iconColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSizes.s12),
                        Expanded(
                          child: StatsCard(
                            icon: Icons.attach_money_rounded,
                            value:
                                '\$${stats.totalRevenue.toStringAsFixed(0)}',
                            label: 'Revenue',
                            trend: '+8%',
                            trendPositive: true,
                            iconColor: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.s12),
                    Row(
                      children: [
                        Expanded(
                          child: StatsCard(
                            icon: Icons.people_rounded,
                            value: stats.activeUsers.toString(),
                            label: 'Active Users',
                            trend: '+5%',
                            trendPositive: true,
                            iconColor: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: AppSizes.s12),
                        Expanded(
                          child: StatsCard(
                            icon: Icons.timer_rounded,
                            value:
                                '${stats.avgDeliveryTimeMinutes.toStringAsFixed(0)} min',
                            label: 'Avg Delivery',
                            trend: '-3%',
                            trendPositive: true,
                            iconColor: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.s24),

                    // Revenue Chart
                    RevenueChart(revenueData: stats.revenueByDay),
                  ],
                ),
                loading: () => const SizedBox(
                  height: 300,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                error: (error, _) => Container(
                  padding: AppSizes.paddingAllL,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: AppSizes.borderRadiusM,
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: AppSizes.s8),
                      Text(
                        'Failed to load dashboard data',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: AppSizes.s8),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(dashboardStatsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.s24),

              // Quick Actions
              Text('Quick Actions', style: AppTypography.titleMedium),
              const SizedBox(height: AppSizes.s12),
              _QuickActionsRow(
                onRestaurantsTap: () =>
                    context.go(RoutePaths.adminRestaurants),
                onUsersTap: () => context.go(RoutePaths.adminUsers),
                onOrdersTap: () => context.go(RoutePaths.adminOrders),
                onPromotionsTap: () =>
                    context.go(RoutePaths.adminPromotions),
              ),
              const SizedBox(height: AppSizes.s24),

              // Recent Orders Table
              recentOrdersAsync.when(
                data: (orders) => RecentOrdersTable(
                  orders: orders,
                  onOrderTap: (orderId) {
                    context.go(
                      RoutePaths.adminOrders,
                    );
                  },
                ),
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                error: (error, _) => Container(
                  padding: AppSizes.paddingAllM,
                  child: Text(
                    'Failed to load recent orders',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.s32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    const periods = [
      ('today', 'Today'),
      ('week', 'This Week'),
      ('month', 'This Month'),
      ('year', 'This Year'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((period) {
          final isSelected = selectedPeriod == period.$1;
          return Padding(
            padding: const EdgeInsets.only(right: AppSizes.s8),
            child: ChoiceChip(
              label: Text(period.$2),
              selected: isSelected,
              onSelected: (_) => onPeriodChanged(period.$1),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              labelStyle: AppTypography.labelMedium.copyWith(
                color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppSizes.borderRadiusPill,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onRestaurantsTap,
    required this.onUsersTap,
    required this.onOrdersTap,
    required this.onPromotionsTap,
  });

  final VoidCallback onRestaurantsTap;
  final VoidCallback onUsersTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onPromotionsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickActionButton(
          icon: Icons.restaurant_rounded,
          label: 'Restaurants',
          color: AppColors.primary,
          onTap: onRestaurantsTap,
        ),
        const SizedBox(width: AppSizes.s12),
        _QuickActionButton(
          icon: Icons.people_rounded,
          label: 'Users',
          color: AppColors.info,
          onTap: onUsersTap,
        ),
        const SizedBox(width: AppSizes.s12),
        _QuickActionButton(
          icon: Icons.receipt_long_rounded,
          label: 'Orders',
          color: AppColors.success,
          onTap: onOrdersTap,
        ),
        const SizedBox(width: AppSizes.s12),
        _QuickActionButton(
          icon: Icons.local_offer_rounded,
          label: 'Promos',
          color: AppColors.warning,
          onTap: onPromotionsTap,
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSizes.borderRadiusM,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.s16,
            horizontal: AppSizes.s8,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: AppSizes.borderRadiusM,
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: AppSizes.iconL),
              const SizedBox(height: AppSizes.s8),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
