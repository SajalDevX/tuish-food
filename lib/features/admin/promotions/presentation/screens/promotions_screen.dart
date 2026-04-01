import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/features/admin/promotions/presentation/providers/promotions_provider.dart';
import 'package:tuish_food/features/admin/promotions/presentation/widgets/promotion_card.dart';
import 'package:tuish_food/routing/route_paths.dart';

class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: TuishAppBar(
          title: AppStrings.promotions,
          showBackButton: false,
        ),
        body: Column(
          children: [
            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSizes.s16,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppSizes.borderRadiusM,
              ),
              child: TabBar(
                labelColor: AppColors.onPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTypography.labelLarge,
                unselectedLabelStyle: AppTypography.labelMedium,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppSizes.borderRadiusM,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Expired'),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.s8),

            // Tab views
            Expanded(
              child: TabBarView(
                children: [
                  _ActivePromotionsTab(),
                  _ExpiredPromotionsTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push(RoutePaths.createPromotion),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: AppColors.onPrimary),
        ),
      ),
    );
  }
}

class _ActivePromotionsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionsAsync = ref.watch(activePromotionsProvider);

    return promotionsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => EmptyStateWidget(
        message: 'Failed to load promotions',
        icon: Icons.error_outline,
        actionLabel: AppStrings.retry,
        onAction: () => ref.invalidate(allPromotionsProvider),
      ),
      data: (promotions) {
        if (promotions.isEmpty) {
          return const EmptyStateWidget(
            message: 'No active promotions.\nTap + to create one.',
            icon: Icons.local_offer_outlined,
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(allPromotionsProvider);
          },
          child: ListView.builder(
            padding: AppSizes.screenPadding,
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final doc = promotions[index];
              return PromotionCard(data: doc.data());
            },
          ),
        );
      },
    );
  }
}

class _ExpiredPromotionsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionsAsync = ref.watch(expiredPromotionsProvider);

    return promotionsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => EmptyStateWidget(
        message: 'Failed to load promotions',
        icon: Icons.error_outline,
        actionLabel: AppStrings.retry,
        onAction: () => ref.invalidate(allPromotionsProvider),
      ),
      data: (promotions) {
        if (promotions.isEmpty) {
          return const EmptyStateWidget(
            message: 'No expired promotions.',
            icon: Icons.history,
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(allPromotionsProvider);
          },
          child: ListView.builder(
            padding: AppSizes.screenPadding,
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final doc = promotions[index];
              return PromotionCard(data: doc.data());
            },
          ),
        );
      },
    );
  }
}
