import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/confirmation_dialog.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_text_field.dart';
import 'package:tuish_food/features/admin/restaurant_management/presentation/providers/restaurant_management_provider.dart';
import 'package:tuish_food/features/admin/restaurant_management/presentation/widgets/restaurant_table_row.dart';
import 'package:tuish_food/routing/route_paths.dart';

class RestaurantsListScreen extends ConsumerWidget {
  const RestaurantsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredRestaurantsProvider);
    final filter = ref.watch(restaurantFilterProvider);
    final searchController = TextEditingController(
      text: ref.watch(restaurantSearchProvider),
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: TuishAppBar(
        title: 'Restaurants',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(allRestaurantsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(RoutePaths.addRestaurant),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Restaurant'),
      ),
      body: Column(
        children: [
          // Search & filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.s16,
              AppSizes.s8,
              AppSizes.s16,
              AppSizes.s4,
            ),
            child: TuishTextField(
              hint: 'Search restaurants...',
              controller: searchController,
              prefixIcon: const Icon(Icons.search_rounded),
              onChanged: (value) {
                ref.read(restaurantSearchProvider.notifier).update(value);
              },
            ),
          ),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: AppSizes.paddingHorizontalM,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: filter == 'all',
                  onTap: () =>
                      ref.read(restaurantFilterProvider.notifier).update('all'),
                ),
                const SizedBox(width: AppSizes.s8),
                _FilterChip(
                  label: 'Active',
                  isSelected: filter == 'active',
                  onTap: () =>
                      ref.read(restaurantFilterProvider.notifier).update(
                          'active'),
                ),
                const SizedBox(width: AppSizes.s8),
                _FilterChip(
                  label: 'Inactive',
                  isSelected: filter == 'inactive',
                  onTap: () =>
                      ref.read(restaurantFilterProvider.notifier).update(
                          'inactive'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.s8),

          // List
          Expanded(
            child: filteredAsync.when(
              data: (restaurants) {
                if (restaurants.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'No restaurants found',
                    icon: Icons.restaurant_rounded,
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(allRestaurantsProvider);
                  },
                  child: ListView.builder(
                    padding: AppSizes.paddingHorizontalM,
                    itemCount: restaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = restaurants[index];
                      return RestaurantTableRow(
                        restaurant: restaurant,
                        onTap: () {
                          context.go(
                            RoutePaths.editRestaurant
                                .replaceFirst(':id', restaurant.id),
                          );
                        },
                        onEdit: () {
                          context.go(
                            RoutePaths.editRestaurant
                                .replaceFirst(':id', restaurant.id),
                          );
                        },
                        onMenuTap: () {
                          context.go(
                            RoutePaths.restaurantMenu
                                .replaceFirst(':id', restaurant.id),
                          );
                        },
                        onToggleStatus: () async {
                          await ref
                              .read(restaurantCrudProvider.notifier)
                              .toggleStatus(
                                  restaurant.id, !restaurant.isActive);
                        },
                        onDelete: () async {
                          final confirmed = await ConfirmationDialog.show(
                            context,
                            title: 'Delete Restaurant',
                            message:
                                'Are you sure you want to delete "${restaurant.name}"? This action cannot be undone.',
                            confirmLabel: 'Delete',
                          );
                          if (confirmed == true) {
                            await ref
                                .read(restaurantCrudProvider.notifier)
                                .deleteRestaurant(restaurant.id);
                          }
                        },
                      );
                    },
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
                    Text(
                      'Failed to load restaurants',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s8),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(allRestaurantsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
        backgroundColor:
            isSelected ? AppColors.primary : AppColors.surface,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSizes.borderRadiusPill,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
      ),
    );
  }
}
