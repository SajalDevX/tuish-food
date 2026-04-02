import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/core/widgets/status_badge.dart';
import 'package:tuish_food/core/widgets/tuish_card.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/providers/restaurant_owner_provider.dart';
import 'package:tuish_food/routing/route_paths.dart';

class RestaurantDashboardScreen extends ConsumerWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(myRestaurantProvider);

    return restaurantAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: const TuishAppBar(title: 'Dashboard', showBackButton: false),
        body: Center(child: Text('Error: $e')),
      ),
      data: (restaurant) {
        if (restaurant == null) {
          return _buildNoRestaurant(context);
        }
        return _buildDashboard(context, ref, restaurant);
      },
    );
  }

  Widget _buildNoRestaurant(BuildContext context) {
    return Scaffold(
        appBar: const TuishAppBar(
          title: 'Dashboard',
          showBackButton: false,
        ),
        body: Center(
          child: Padding(
            padding: AppSizes.paddingAllL,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 80,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: AppSizes.s24),
                Text(
                  'Set up your restaurant',
                  style: AppTypography.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.s8),
                Text(
                  'Create your restaurant profile to start receiving orders.',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.s32),
                TuishButton.primary(
                  label: 'Set Up Restaurant',
                  onPressed: () => context.push(RoutePaths.restaurantSetup),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    Restaurant restaurant,
  ) {
    return Scaffold(
      appBar: const TuishAppBar(
        title: 'Dashboard',
        showBackButton: false,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(myRestaurantProvider);
        },
        child: ListView(
          padding: AppSizes.screenPadding,
          children: [
            // Open/Closed toggle
            _OpenClosedToggle(
              isOpen: restaurant.isOpen,
              restaurantId: restaurant.id,
            ),
            const SizedBox(height: AppSizes.s20),

            // Stat cards row
            _StatCardsRow(restaurant: restaurant),
            const SizedBox(height: AppSizes.s24),

            // Recent orders header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Orders', style: AppTypography.titleMedium),
                TextButton(
                  onPressed: () =>
                      context.go(RoutePaths.restaurantOrders),
                  child: Text(
                    'View All',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s8),

            // Recent orders from provider
            ref.watch(myRestaurantOrdersProvider).when(
                  data: (orders) {
                    if (orders.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.s24),
                        child: Center(
                          child: Text(
                            'No orders yet',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }
                    final recent = orders.take(5).toList();
                    return Column(
                      children: recent.map((order) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSizes.s8),
                          child: TuishCard(
                            onTap: () {
                              context.push(
                                RoutePaths.restaurantOrderDetail
                                    .replaceFirst(':orderId', order.id),
                              );
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.orderNumber.isNotEmpty
                                            ? order.orderNumber
                                            : 'Order #${order.id.length >= 6 ? order.id.substring(0, 6).toUpperCase() : order.id.toUpperCase()}',
                                        style: AppTypography.titleSmall,
                                      ),
                                      const SizedBox(
                                          height: AppSizes.s4),
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
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSizes.s24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Open/Closed toggle
// -----------------------------------------------------------------------------

class _OpenClosedToggle extends StatefulWidget {
  const _OpenClosedToggle({
    required this.isOpen,
    required this.restaurantId,
  });

  final bool isOpen;
  final String restaurantId;

  @override
  State<_OpenClosedToggle> createState() => _OpenClosedToggleState();
}

class _OpenClosedToggleState extends State<_OpenClosedToggle> {
  late bool _isOpen;

  @override
  void initState() {
    super.initState();
    _isOpen = widget.isOpen;
  }

  @override
  Widget build(BuildContext context) {
    return TuishCard(
      color: _isOpen
          ? AppColors.success.withValues(alpha: 0.08)
          : AppColors.error.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(
            _isOpen ? Icons.storefront : Icons.store_outlined,
            color: _isOpen ? AppColors.success : AppColors.error,
            size: AppSizes.iconL,
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOpen ? 'Restaurant Open' : 'Restaurant Closed',
                  style: AppTypography.titleSmall.copyWith(
                    color: _isOpen ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(height: AppSizes.s4),
                Text(
                  _isOpen
                      ? 'You are accepting orders'
                      : 'Toggle to start accepting orders',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isOpen,
            activeTrackColor: AppColors.success,
            onChanged: (value) async {
              setState(() => _isOpen = value);
              try {
                await FirebaseFirestore.instance
                    .collection('restaurants')
                    .doc(widget.restaurantId)
                    .update({
                      'isOpen': value,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
              } catch (_) {
                if (mounted) setState(() => _isOpen = !value);
              }
            },
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Stat cards row
// -----------------------------------------------------------------------------

class _StatCardsRow extends StatelessWidget {
  const _StatCardsRow({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.receipt_long,
            iconColor: AppColors.statusPlaced,
            label: 'Total Orders',
            value: '${restaurant.totalOrders}',
          ),
        ),
        const SizedBox(width: AppSizes.s12),
        Expanded(
          child: _StatCard(
            icon: Icons.people_outline,
            iconColor: AppColors.success,
            label: 'Ratings',
            value: '${restaurant.totalRatings}',
          ),
        ),
        const SizedBox(width: AppSizes.s12),
        Expanded(
          child: _StatCard(
            icon: Icons.star,
            iconColor: AppColors.starFilled,
            label: 'Rating',
            value: restaurant.averageRating.toStringAsFixed(1),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return TuishCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s12,
        vertical: AppSizes.s16,
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: AppSizes.iconL),
          const SizedBox(height: AppSizes.s8),
          Text(value, style: AppTypography.titleLarge),
          const SizedBox(height: AppSizes.s4),
          Text(
            label,
            style: AppTypography.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

