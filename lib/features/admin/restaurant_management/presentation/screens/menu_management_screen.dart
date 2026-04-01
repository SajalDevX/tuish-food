import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/cached_image.dart';
import 'package:tuish_food/core/widgets/confirmation_dialog.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/features/admin/restaurant_management/presentation/providers/restaurant_management_provider.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_item.dart';

class MenuManagementScreen extends ConsumerWidget {
  const MenuManagementScreen({
    super.key,
    required this.restaurantId,
  });

  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItemsAsync = ref.watch(menuItemsProvider(restaurantId));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: TuishAppBar(
        title: 'Menu Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.invalidate(menuItemsProvider(restaurantId)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.go(
            '/admin/restaurants/$restaurantId/menu/add',
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Item'),
      ),
      body: menuItemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyStateWidget(
              message: 'No menu items yet.\nAdd your first item!',
              icon: Icons.menu_book_rounded,
            );
          }

          // Group by category
          final Map<String, List<MenuItem>> grouped = {};
          for (final item in items) {
            final cat = item.categoryId.isNotEmpty
                ? item.categoryId
                : 'Uncategorized';
            grouped.putIfAbsent(cat, () => []).add(item);
          }

          return ListView(
            padding: AppSizes.paddingAllM,
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSizes.s16,
                      bottom: AppSizes.s8,
                    ),
                    child: Text(
                      entry.key,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  ...entry.value.map((item) => _MenuItemTile(
                        item: item,
                        restaurantId: restaurantId,
                      )),
                ],
              );
            }).toList(),
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
                'Failed to load menu items',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.error),
              ),
              TextButton(
                onPressed: () =>
                    ref.invalidate(menuItemsProvider(restaurantId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItemTile extends ConsumerWidget {
  const _MenuItemTile({
    required this.item,
    required this.restaurantId,
  });

  final MenuItem item;
  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.s8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppSizes.borderRadiusM,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: AppSizes.paddingAllM,
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: AppSizes.borderRadiusS,
              child: item.imageUrl.isNotEmpty
                  ? CachedImage(
                      imageUrl: item.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: AppColors.background,
                      child: const Icon(
                        Icons.fastfood_rounded,
                        color: AppColors.textHint,
                      ),
                    ),
            ),
            const SizedBox(width: AppSizes.s12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.isVegetarian)
                        Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.vegGreen,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Center(
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.vegGreen,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.nonVegRed,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Center(
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.nonVegRed,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          item.name,
                          style: AppTypography.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.s4),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!item.isAvailable)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSizes.s4),
                      child: Text(
                        'Unavailable',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                Switch.adaptive(
                  value: item.isAvailable,
                  onChanged: (value) async {
                    await ref
                        .read(menuCrudProvider.notifier)
                        .updateMenuItem(
                          restaurantId,
                          item.id,
                          {'isAvailable': value},
                        );
                  },
                  activeTrackColor: AppColors.primary,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirmed = await ConfirmationDialog.show(
                        context,
                        title: 'Delete Item',
                        message:
                            'Are you sure you want to delete "${item.name}"?',
                        confirmLabel: 'Delete',
                      );
                      if (confirmed == true) {
                        await ref
                            .read(menuCrudProvider.notifier)
                            .deleteMenuItem(restaurantId, item.id);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded,
                              size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
