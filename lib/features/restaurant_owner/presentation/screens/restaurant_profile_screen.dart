import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/glass_scaffold.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/features/auth/presentation/providers/auth_provider.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/providers/restaurant_owner_provider.dart';
import 'package:tuish_food/routing/route_paths.dart';

class RestaurantProfileScreen extends ConsumerWidget {
  const RestaurantProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(myRestaurantProvider);

    return restaurantAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: const TuishAppBar(title: 'My Restaurant'),
        body: Center(child: Text('Error: $e')),
      ),
      data: (restaurant) => _buildProfile(context, ref, restaurant),
    );
  }

  Widget _buildProfile(
    BuildContext context,
    WidgetRef ref,
    Restaurant? restaurant,
  ) {
    final name = restaurant?.name ?? 'Your Restaurant';
    final subtitle = restaurant != null
        ? restaurant.cuisineTypes.join(', ')
        : 'Set up your restaurant to get started';

    return GlassScaffold(
      appBar: const TuishAppBar(title: 'My Restaurant'),
      body: ListView(
        padding: EdgeInsets.only(
          left: AppSizes.s24,
          right: AppSizes.s24,
          bottom: AppSizes.s24,
          // Account for glass AppBar overlapping the body
          top: MediaQuery.of(context).padding.top + kToolbarHeight + AppSizes.s16,
        ),
        children: [
          // Restaurant header
          Container(
            padding: AppSizes.paddingAllL,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: AppSizes.borderRadiusL,
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSizes.s12),
                Text(
                  name,
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSizes.s4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.s24),

          // Info cards
          _buildInfoCard(
            icon: Icons.restaurant_menu,
            title: 'Cuisine Types',
            value: restaurant?.cuisineTypes.join(', ') ?? 'Not set',
          ),
          _buildInfoCard(
            icon: Icons.location_on_outlined,
            title: 'Address',
            value: restaurant?.address.fullAddress ?? 'Not set',
          ),
          _buildInfoCard(
            icon: Icons.delivery_dining,
            title: 'Delivery Fee',
            value: '\u20B9${restaurant?.deliveryFee.toStringAsFixed(0) ?? '0'}',
          ),
          _buildInfoCard(
            icon: Icons.shopping_bag_outlined,
            title: 'Minimum Order',
            value:
                '\u20B9${restaurant?.minimumOrderAmount.toStringAsFixed(0) ?? '0'}',
          ),
          _buildInfoCard(
            icon: Icons.timer_outlined,
            title: 'Prep Time',
            value: '${restaurant?.preparationTimeMinutes ?? 0} min',
          ),
          _buildInfoCard(
            icon: Icons.star_rounded,
            title: 'Rating',
            value:
                '${restaurant?.averageRating.toStringAsFixed(1) ?? '0.0'} (${restaurant?.totalRatings ?? 0} reviews)',
          ),
          _buildInfoCard(
            icon: Icons.receipt_long_outlined,
            title: 'Total Orders',
            value: '${restaurant?.totalOrders ?? 0}',
          ),

          const SizedBox(height: AppSizes.s24),
          TuishButton.primary(
            label: 'Edit Restaurant Details',
            onPressed: () {
              context.push(RoutePaths.restaurantSetup);
            },
          ),
          const SizedBox(height: AppSizes.s12),
          TuishButton.outlined(
            label: 'Sign Out',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).signOut();
              context.go(RoutePaths.login);
            },
          ),
          const SizedBox(height: AppSizes.s32),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s8),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title, style: AppTypography.labelMedium),
          subtitle: Text(value, style: AppTypography.bodyLarge),
        ),
      ),
    );
  }
}
