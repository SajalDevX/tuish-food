import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/error_widget.dart';
import 'package:tuish_food/features/customer/cart/presentation/providers/cart_provider.dart';
import 'package:tuish_food/features/customer/cart/presentation/widgets/cart_fab.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_category.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_item.dart';
import 'package:tuish_food/features/customer/menu/presentation/providers/menu_provider.dart';
import 'package:tuish_food/features/customer/menu/presentation/widgets/item_detail_bottom_sheet.dart';
import 'package:tuish_food/features/customer/menu/presentation/widgets/menu_item_card.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  final String restaurantId;
  final String restaurantName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(menuCategoriesProvider(restaurantId));
    final itemsAsync = ref.watch(menuItemsProvider(restaurantId));
    final vegFilter = ref.watch(vegFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurantName),
        actions: [
          // Veg/Non-veg filter
          PopupMenuButton<bool?>(
            icon: Icon(
              Icons.filter_list,
              color: vegFilter != null
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            onSelected: (value) {
              ref.read(vegFilterProvider.notifier).update(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All')),
              PopupMenuItem(
                value: true,
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.vegGreen,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.vegGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.s8),
                    const Text('Veg Only'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: false,
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.nonVegRed,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.nonVegRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.s8),
                    const Text('Non-Veg Only'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => TuishErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(menuCategoriesProvider(restaurantId)),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Text(
                'No menu categories available',
                style: AppTypography.bodyLarge,
              ),
            );
          }

          return itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => TuishErrorWidget(
              message: error.toString(),
              onRetry: () => ref.invalidate(menuItemsProvider(restaurantId)),
            ),
            data: (allItems) {
              return _MenuTabView(
                categories: categories,
                allItems: allItems,
                vegFilter: vegFilter,
                restaurantId: restaurantId,
                restaurantName: restaurantName,
              );
            },
          );
        },
      ),
      floatingActionButton: const CartFab(),
    );
  }
}

class _MenuTabView extends ConsumerStatefulWidget {
  const _MenuTabView({
    required this.categories,
    required this.allItems,
    required this.vegFilter,
    required this.restaurantId,
    required this.restaurantName,
  });

  final List<MenuCategory> categories;
  final List<MenuItem> allItems;
  final bool? vegFilter;
  final String restaurantId;
  final String restaurantName;

  @override
  ConsumerState<_MenuTabView> createState() => _MenuTabViewState();
}

class _MenuTabViewState extends ConsumerState<_MenuTabView>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.categories.length,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(covariant _MenuTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categories.length != widget.categories.length) {
      _tabController.dispose();
      _tabController = TabController(
        length: widget.categories.length,
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<MenuItem> _filteredItems(String categoryId) {
    var items = widget.allItems
        .where((item) => item.categoryId == categoryId)
        .toList();

    // Apply veg filter
    if (widget.vegFilter == true) {
      items = items.where((item) => item.isVegetarian).toList();
    } else if (widget.vegFilter == false) {
      items = items.where((item) => !item.isVegetarian).toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final cartNotifier = ref.read(cartNotifierProvider.notifier);

    return Column(
      children: [
        // Category tabs
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabAlignment: TabAlignment.start,
          tabs: widget.categories.map((cat) => Tab(text: cat.name)).toList(),
        ),

        // Menu items
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.categories.map((category) {
              final items = _filteredItems(category.id);

              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'No items in this category',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  indent: AppSizes.s16,
                  endIndent: AppSizes.s16,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final quantity = cartNotifier.getSimpleItemQuantity(item.id);

                  return MenuItemCard(
                    item: item,
                    quantity: quantity,
                    onTap: () {
                      ItemDetailBottomSheet.show(
                        context,
                        item: item,
                        restaurantId: widget.restaurantId,
                        restaurantName: widget.restaurantName,
                      );
                    },
                    onAddToCart: () {
                      if (item.hasCustomizations) {
                        ItemDetailBottomSheet.show(
                          context,
                          item: item,
                          restaurantId: widget.restaurantId,
                          restaurantName: widget.restaurantName,
                        );
                      } else {
                        cartNotifier.incrementSimpleItem(
                          item.id,
                          name: item.name,
                          imageUrl: item.imageUrl,
                          price: item.effectivePrice,
                          restaurantId: widget.restaurantId,
                          restaurantName: widget.restaurantName,
                          context: context,
                        );
                      }
                    },
                    onIncrement: () {
                      cartNotifier.incrementSimpleItem(
                        item.id,
                        name: item.name,
                        imageUrl: item.imageUrl,
                        price: item.effectivePrice,
                        restaurantId: widget.restaurantId,
                        restaurantName: widget.restaurantName,
                        context: context,
                      );
                    },
                    onDecrement: () {
                      cartNotifier.decrementSimpleItem(item.id);
                    },
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
