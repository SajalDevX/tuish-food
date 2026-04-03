import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/cached_image.dart';
import 'package:tuish_food/core/widgets/glass_scaffold.dart';
import 'package:tuish_food/core/widgets/rating_bar.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';
import 'package:tuish_food/features/customer/home/presentation/providers/home_provider.dart';

class RestaurantDetailScreen extends ConsumerWidget {
  const RestaurantDetailScreen({
    super.key,
    required this.restaurantId,
  });

  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(restaurantDetailProvider(restaurantId));

    return GlassScaffold(
      body: restaurantAsync.when(
        data: (restaurant) => _buildContent(context, restaurant),
        loading: () => _buildLoadingState(),
        error: (error, _) => _buildErrorState(context, ref, error),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Restaurant restaurant) {
    return CustomScrollView(
      slivers: [
        // ---- Cover Image with Back Button Overlay ----
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: AppColors.surface,
          leading: Padding(
            padding: const EdgeInsets.all(AppSizes.s8),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.9),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: AppSizes.iconS,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Hero(
              tag: 'restaurant_image_$restaurantId',
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedImage(
                    imageUrl: restaurant.coverImageUrl.isNotEmpty
                        ? restaurant.coverImageUrl
                        : restaurant.imageUrl,
                    fit: BoxFit.cover,
                  ),
                  // Gradient overlay for readability
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black54,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSizes.s8),
              child: CircleAvatar(
                backgroundColor:
                    Theme.of(context).cardColor.withValues(alpha: 0.9),
                child: IconButton(
                  icon: const Icon(
                    Icons.share_outlined,
                    size: AppSizes.iconS,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () {
                    // Share functionality
                  },
                ),
              ),
            ),
          ],
        ),

        // ---- Restaurant Info ----
        SliverToBoxAdapter(
          child: Container(
            color: Theme.of(context).cardColor,
            padding: AppSizes.paddingAllM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and open/closed status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        restaurant.name,
                        style: AppTypography.headlineSmall,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s12,
                        vertical: AppSizes.s4,
                      ),
                      decoration: BoxDecoration(
                        color: restaurant.isOpen
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: AppSizes.borderRadiusPill,
                      ),
                      child: Text(
                        restaurant.isOpen ? 'Open' : 'Closed',
                        style: AppTypography.labelSmall.copyWith(
                          color: restaurant.isOpen
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.s8),

                // Cuisine types
                Text(
                  restaurant.cuisineTypesLabel,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.s12),

                // Rating, delivery fee, prep time row
                Row(
                  children: [
                    // Rating
                    Row(
                      children: [
                        TuishRatingBar(
                          rating: restaurant.averageRating,
                          size: 18,
                        ),
                        const SizedBox(width: AppSizes.s4),
                        Text(
                          '${restaurant.averageRating.toStringAsFixed(1)} (${restaurant.totalRatings})',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.s12),

                // Info chips row
                Wrap(
                  spacing: AppSizes.s12,
                  runSpacing: AppSizes.s8,
                  children: [
                    _buildInfoChip(
                      icon: Icons.access_time_rounded,
                      label: restaurant.deliveryTimeLabel,
                    ),
                    _buildInfoChip(
                      icon: Icons.delivery_dining_outlined,
                      label: restaurant.deliveryFeeLabel,
                    ),
                    _buildInfoChip(
                      icon: Icons.attach_money_rounded,
                      label: restaurant.priceLevelLabel,
                    ),
                    if (restaurant.minimumOrderAmount > 0)
                      _buildInfoChip(
                        icon: Icons.shopping_bag_outlined,
                        label:
                            'Min \$${restaurant.minimumOrderAmount.toStringAsFixed(2)}',
                      ),
                  ],
                ),

                if (restaurant.freeDeliveryAbove > 0) ...[
                  const SizedBox(height: AppSizes.s8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s12,
                      vertical: AppSizes.s8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: AppSizes.borderRadiusS,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_offer_outlined,
                          size: AppSizes.iconS,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: AppSizes.s4),
                        Text(
                          'Free delivery above \$${restaurant.freeDeliveryAbove.toStringAsFixed(2)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: AppSizes.s8),
        ),

        // ---- Description ----
        if (restaurant.description.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              color: Theme.of(context).cardColor,
              padding: AppSizes.paddingAllM,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSizes.s8),
                  Text(
                    restaurant.description,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: AppSizes.s8),
        ),

        // ---- Operating Hours ----
        if (restaurant.operatingHours.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              color: Theme.of(context).cardColor,
              padding: AppSizes.paddingAllM,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Operating Hours', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSizes.s12),
                  ...restaurant.operatingHours.map(
                    (hours) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.s8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            hours.day,
                            style: AppTypography.bodyMedium,
                          ),
                          Text(
                            hours.isClosed
                                ? 'Closed'
                                : '${hours.openTime} - ${hours.closeTime}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: hours.isClosed
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: AppSizes.s8),
        ),

        // ---- Reviews Preview ----
        SliverToBoxAdapter(
          child: Container(
            color: Theme.of(context).cardColor,
            padding: AppSizes.paddingAllM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Reviews', style: AppTypography.titleMedium),
                    Text(
                      AppStrings.seeAll,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.s12),
                Row(
                  children: [
                    Text(
                      restaurant.averageRating.toStringAsFixed(1),
                      style: AppTypography.headlineLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TuishRatingBar(
                          rating: restaurant.averageRating,
                          size: 20,
                        ),
                        const SizedBox(height: AppSizes.s4),
                        Text(
                          '${restaurant.totalRatings} ratings',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ---- Address ----
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSizes.s8),
        ),

        SliverToBoxAdapter(
          child: Container(
            color: Theme.of(context).cardColor,
            padding: AppSizes.paddingAllM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Location', style: AppTypography.titleMedium),
                const SizedBox(height: AppSizes.s8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.textSecondary,
                      size: AppSizes.iconM,
                    ),
                    const SizedBox(width: AppSizes.s8),
                    Expanded(
                      child: Text(
                        restaurant.address.fullAddress,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bottom spacing for the button
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s12,
        vertical: AppSizes.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppSizes.borderRadiusPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconS, color: AppColors.textSecondary),
          const SizedBox(width: AppSizes.s4),
          Text(label, style: AppTypography.labelSmall),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 240, color: AppColors.shimmerBase),
            Padding(
              padding: AppSizes.paddingAllM,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 24,
                    width: 200,
                    decoration: BoxDecoration(
                      color: AppColors.shimmerBase,
                      borderRadius: AppSizes.borderRadiusS,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s12),
                  Container(
                    height: 14,
                    width: 150,
                    decoration: BoxDecoration(
                      color: AppColors.shimmerBase,
                      borderRadius: AppSizes.borderRadiusS,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s12),
                  Container(
                    height: 14,
                    width: 250,
                    decoration: BoxDecoration(
                      color: AppColors.shimmerBase,
                      borderRadius: AppSizes.borderRadiusS,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s24),
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.shimmerBase,
                      borderRadius: AppSizes.borderRadiusM,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    Object error,
  ) {
    return Center(
      child: Padding(
        padding: AppSizes.paddingAllL,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: AppSizes.iconXL,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.s16),
            Text(
              'Failed to load restaurant',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.s24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TuishButton.outlined(
                  label: 'Go Back',
                  isFullWidth: false,
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: AppSizes.s12),
                TuishButton.primary(
                  label: AppStrings.retry,
                  isFullWidth: false,
                  onPressed: () {
                    ref.invalidate(restaurantDetailProvider(restaurantId));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
