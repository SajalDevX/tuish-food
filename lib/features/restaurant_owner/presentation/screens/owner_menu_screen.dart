import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/glass_scaffold.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/core/widgets/staggered_fade_slide.dart';
import 'package:tuish_food/core/widgets/tuish_card.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_item.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/providers/restaurant_owner_provider.dart';
import 'package:tuish_food/routing/route_paths.dart';

class OwnerMenuScreen extends ConsumerWidget {
  const OwnerMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(myMenuItemsProvider);

    return GlassScaffold(
      appBar: const TuishAppBar(
        title: 'Menu',
        showBackButton: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.restaurantAddMenuItem),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.restaurant_menu_outlined,
              message: 'Add your first menu item',
              actionLabel: 'Add Item',
              onAction: () => context.push(RoutePaths.restaurantAddMenuItem),
            );
          }
          return _MenuList(items: items);
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Menu list grouped by category
// -----------------------------------------------------------------------------

class _MenuList extends StatelessWidget {
  const _MenuList({required this.items});

  final List<MenuItem> items;

  /// Converts raw category IDs like "cat_biryani" to "Biryani".
  String _formatCategoryName(String raw) {
    if (!raw.startsWith('cat_')) return raw;
    final name = raw.substring(4);
    if (name.isEmpty) return raw;
    return name[0].toUpperCase() + name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    // Group items by category.
    final grouped = <String, List<MenuItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.categoryId, () => []).add(item);
    }

    final categories = grouped.keys.toList();

    return ListView.builder(
      padding: AppSizes.screenPadding,
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryItems = grouped[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: AppSizes.s16),
            Text(
              _formatCategoryName(category),
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSizes.s8),
            ...categoryItems.indexed.map((entry) => StaggeredFadeSlide(
              index: entry.$1,
              child: _MenuItemCard(item: entry.$2),
            )),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Individual menu item card
// -----------------------------------------------------------------------------

class _MenuItemCard extends ConsumerStatefulWidget {
  const _MenuItemCard({required this.item});

  final MenuItem item;

  @override
  ConsumerState<_MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends ConsumerState<_MenuItemCard> {
  late bool _isAvailable;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.item.isAvailable;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s12),
      child: TuishCard(
        onTap: () {
          context.push(
            RoutePaths.restaurantEditMenuItem.replaceFirst(
              ':itemId',
              widget.item.id,
            ),
          );
        },
        child: Row(
          children: [
            // Veg / Non-veg badge
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.item.isVegetarian
                      ? AppColors.vegGreen
                      : AppColors.nonVegRed,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.item.isVegetarian
                        ? AppColors.vegGreen
                        : AppColors.nonVegRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.s12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: AppTypography.titleSmall.copyWith(
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.s4),
                  Text(
                    '\u20B9${widget.item.price.toInt()}',
                    style: AppTypography.priceSmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            // Availability toggle
            Column(
              children: [
                Switch.adaptive(
                  value: _isAvailable,
                  activeTrackColor: AppColors.success,
                  onChanged: (value) async {
                    setState(() => _isAvailable = value);
                    final restaurantId = ref.read(myRestaurantIdProvider);
                    if (restaurantId == null) return;
                    try {
                      await updateMenuItemAvailability(
                        ref,
                        restaurantId: restaurantId,
                        itemId: widget.item.id,
                        isAvailable: value,
                      );
                    } catch (_) {
                      if (mounted) setState(() => _isAvailable = !value);
                    }
                  },
                ),
                Text(
                  _isAvailable ? 'Available' : 'Unavailable',
                  style: AppTypography.labelSmall.copyWith(
                    color: _isAvailable
                        ? AppColors.success
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
