import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/cached_image.dart';
import 'package:tuish_food/core/widgets/glass_scaffold.dart';
import 'package:tuish_food/core/widgets/price_tag.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/features/customer/cart/domain/entities/cart_item.dart';
import 'package:tuish_food/features/customer/checkout/domain/entities/checkout_order_draft.dart';
import 'package:tuish_food/features/customer/home/presentation/providers/home_provider.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_item.dart';
import 'package:tuish_food/features/customer/menu/presentation/providers/menu_provider.dart';
import 'package:tuish_food/features/customer/menu/presentation/widgets/customization_selector.dart';
import 'package:tuish_food/routing/route_names.dart';

class MenuItemDetailScreen extends ConsumerStatefulWidget {
  const MenuItemDetailScreen({
    super.key,
    required this.restaurantId,
    required this.itemId,
  });

  final String restaurantId;
  final String itemId;

  @override
  ConsumerState<MenuItemDetailScreen> createState() =>
      _MenuItemDetailScreenState();
}

class _MenuItemDetailScreenState extends ConsumerState<MenuItemDetailScreen> {
  int _quantity = 1;
  final Map<String, Set<String>> _selectedCustomizations = {};

  @override
  Widget build(BuildContext context) {
    final restaurantAsync = ref.watch(
      restaurantDetailProvider(widget.restaurantId),
    );
    final itemAsync = ref.watch(
      menuItemProvider((
        restaurantId: widget.restaurantId,
        itemId: widget.itemId,
      )),
    );

    return GlassScaffold(
      appBar: const TuishAppBar(title: 'Item Details'),
      body: restaurantAsync.when(
        data: (restaurant) => itemAsync.when(
          data: (item) {
            _initializeSelections(item);
            return _buildContent(context, item, restaurant.name);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, _) => _buildErrorState(error.toString()),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  void _initializeSelections(MenuItem item) {
    if (_selectedCustomizations.isNotEmpty) return;
    for (final customization in item.customizations) {
      _selectedCustomizations[customization.id] = <String>{};
    }
  }

  double _customizationTotal(MenuItem item) {
    double total = 0;
    for (final customization in item.customizations) {
      final selected = _selectedCustomizations[customization.id] ?? {};
      for (final option in customization.options) {
        if (selected.contains(option.id)) {
          total += option.additionalPrice;
        }
      }
    }
    return total;
  }

  bool _allRequiredSelected(MenuItem item) {
    for (final customization in item.customizations) {
      if (customization.required &&
          (_selectedCustomizations[customization.id]?.isEmpty ?? true)) {
        return false;
      }
    }
    return true;
  }

  Map<String, List<String>> get _selectedCustomizationsForCheckout {
    final result = <String, List<String>>{};
    for (final entry in _selectedCustomizations.entries) {
      if (entry.value.isNotEmpty) {
        result[entry.key] = entry.value.toList();
      }
    }
    return result;
  }

  void _continueToCheckout(
    BuildContext context,
    MenuItem item,
    String restaurantName,
  ) {
    if (!_allRequiredSelected(item)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all required customizations'),
        ),
      );
      return;
    }

    final orderItem = CartItem(
      menuItemId: item.id,
      name: item.name,
      imageUrl: item.imageUrl,
      price: item.effectivePrice + _customizationTotal(item),
      quantity: _quantity,
      selectedCustomizations: _selectedCustomizationsForCheckout,
    );

    final draft = CheckoutOrderDraft(
      restaurantId: widget.restaurantId,
      restaurantName: restaurantName,
      items: [orderItem],
    );

    context.pushNamed(RouteNames.checkout, extra: draft);
  }

  Widget _buildContent(
    BuildContext context,
    MenuItem item,
    String restaurantName,
  ) {
    final totalPrice =
        (item.effectivePrice + _customizationTotal(item)) * _quantity;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: AppSizes.paddingAllM,
            children: [
              if (item.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: AppSizes.borderRadiusL,
                  child: CachedImage(
                    imageUrl: item.imageUrl,
                    width: double.infinity,
                    height: 240,
                    borderRadius: AppSizes.borderRadiusL,
                  ),
                )
              else
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppSizes.borderRadiusL,
                    border: Border.all(color: AppColors.divider),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.restaurant_menu,
                    size: AppSizes.iconXL,
                    color: AppColors.textHint,
                  ),
                ),
              const SizedBox(height: AppSizes.s20),
              Row(
                children: [
                  _DietaryIndicator(isVeg: item.isVegetarian),
                  const SizedBox(width: AppSizes.s8),
                  Expanded(
                    child: Text(item.name, style: AppTypography.headlineSmall),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s8),
              Text(
                restaurantName,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.s8),
              PriceTag(
                price: item.price,
                discountedPrice: item.hasDiscount ? item.discountedPrice : null,
              ),
              const SizedBox(height: AppSizes.s8),
              Text(
                item.description,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.s16),
              Wrap(
                spacing: AppSizes.s8,
                runSpacing: AppSizes.s8,
                children: [
                  if (item.isVegan)
                    _InfoTag(label: 'Vegan', color: AppColors.vegGreen),
                  if (item.isGlutenFree)
                    _InfoTag(label: 'Gluten Free', color: AppColors.info),
                  _InfoTag(
                    label: '${item.preparationTimeMinutes} min',
                    color: AppColors.textSecondary,
                  ),
                  if (item.spiceLevel > 0)
                    _InfoTag(
                      label: 'Spice ${item.spiceLevel}/3',
                      color: AppColors.error,
                    ),
                ],
              ),
              if (item.customizations.isNotEmpty) ...[
                const SizedBox(height: AppSizes.s24),
                Text('Customize', style: AppTypography.titleMedium),
                const SizedBox(height: AppSizes.s12),
                ...item.customizations.map(
                  (customization) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.s16),
                    child: CustomizationSelector(
                      customization: customization,
                      selectedOptionIds:
                          _selectedCustomizations[customization.id] ?? {},
                      onChanged: (selected) {
                        setState(() {
                          _selectedCustomizations[customization.id] = selected;
                        });
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSizes.s24),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSizes.s16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: AppSizes.borderRadiusS,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        icon: const Icon(Icons.remove, size: 20),
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                      Text('$_quantity', style: AppTypography.titleSmall),
                      IconButton(
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add, size: 20),
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.s16),
                Expanded(
                  child: TuishButton.primary(
                    label:
                        'Order Item - \u20B9${totalPrice.toStringAsFixed(0)}',
                    onPressed: item.isAvailable
                        ? () =>
                              _continueToCheckout(context, item, restaurantName)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: AppSizes.paddingAllL,
        child: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _DietaryIndicator extends StatelessWidget {
  const _DietaryIndicator({required this.isVeg});

  final bool isVeg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border.all(
          color: isVeg ? AppColors.vegGreen : AppColors.nonVegRed,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isVeg ? AppColors.vegGreen : AppColors.nonVegRed,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s8,
        vertical: AppSizes.s4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSizes.borderRadiusS,
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: color),
      ),
    );
  }
}
