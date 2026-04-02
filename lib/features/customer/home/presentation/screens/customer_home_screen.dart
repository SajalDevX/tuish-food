import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/widgets/glass_scaffold.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/features/customer/home/presentation/providers/home_provider.dart';
import 'package:tuish_food/features/customer/home/presentation/widgets/category_chip.dart';
import 'package:tuish_food/features/customer/home/presentation/widgets/promo_banner.dart';
import 'package:tuish_food/features/customer/home/presentation/widgets/restaurant_card.dart';
import 'package:tuish_food/features/customer/home/presentation/widgets/search_bar_widget.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearbyRestaurants = ref.watch(nearbyRestaurantsProvider);
    final categories = ref.watch(categoriesProvider);

    return GlassScaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(nearbyRestaurantsProvider);
            ref.invalidate(categoriesProvider);
          },
          child: CustomScrollView(
            slivers: [
              // ---- Location / Address Bar ----
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.s16,
                    AppSizes.s12,
                    AppSizes.s16,
                    AppSizes.s4,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: AppSizes.iconM,
                      ),
                      const SizedBox(width: AppSizes.s8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deliver to',
                              style: AppTypography.labelSmall,
                            ),
                            Text(
                              'Current Location',
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () {
                          // Navigate to notifications
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ---- Search Bar ----
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.s16,
                    vertical: AppSizes.s8,
                  ),
                  child: SearchBarWidget(),
                ),
              ),

              // ---- Promo Banners ----
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: AppSizes.s8),
                  child: PromoBanner(),
                ),
              ),

              // ---- Categories Section ----
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.s16,
                    AppSizes.s20,
                    AppSizes.s16,
                    AppSizes.s8,
                  ),
                  child: Text(
                    AppStrings.categories,
                    style: AppTypography.titleMedium,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 100,
                  child: categories.when(
                    data: (cats) => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s16,
                      ),
                      itemCount: cats.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSizes.s4),
                      itemBuilder: (context, index) {
                        return CategoryChip(
                          category: cats[index],
                          onTap: () {
                            // Could navigate to category-filtered list
                          },
                        );
                      },
                    ),
                    loading: () => _buildCategoryShimmer(),
                    error: (_, _) => const Center(
                      child: Text('Failed to load categories'),
                    ),
                  ),
                ),
              ),

              // ---- Nearby Restaurants Section Header ----
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.s16,
                    AppSizes.s16,
                    AppSizes.s16,
                    AppSizes.s8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.nearbyRestaurants,
                        style: AppTypography.titleMedium,
                      ),
                      Text(
                        AppStrings.seeAll,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---- Nearby Restaurants List ----
              nearbyRestaurants.when(
                data: (restaurants) {
                  if (restaurants.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateWidget(
                        message: 'No restaurants found nearby',
                        icon: Icons.restaurant_outlined,
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s16,
                    ),
                    sliver: SliverList.builder(
                      itemCount: restaurants.length,
                      itemBuilder: (context, index) {
                        return RestaurantCard(
                          restaurant: restaurants[index],
                        );
                      },
                    ),
                  );
                },
                loading: () => SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s16,
                  ),
                  sliver: SliverList.builder(
                    itemCount: 3,
                    itemBuilder: (context, index) =>
                        _buildRestaurantCardShimmer(),
                  ),
                ),
                error: (error, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateWidget(
                    message: 'Failed to load restaurants',
                    icon: Icons.error_outline_rounded,
                    actionLabel: AppStrings.retry,
                    onAction: () {
                      ref.invalidate(nearbyRestaurantsProvider);
                    },
                  ),
                ),
              ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSizes.s32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryShimmer() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(width: AppSizes.s12),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.shimmerBase,
          highlightColor: AppColors.shimmerHighlight,
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.shimmerBase,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: AppSizes.s8),
              Container(
                width: 50,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: AppSizes.borderRadiusS,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRestaurantCardShimmer() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s12),
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: AppSizes.cardImageHeight,
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: AppSizes.borderRadiusM,
              ),
            ),
            const SizedBox(height: AppSizes.s12),
            Container(
              width: 200,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: AppSizes.borderRadiusS,
              ),
            ),
            const SizedBox(height: AppSizes.s8),
            Container(
              width: 140,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: AppSizes.borderRadiusS,
              ),
            ),
            const SizedBox(height: AppSizes.s8),
            Container(
              width: 100,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: AppSizes.borderRadiusS,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
