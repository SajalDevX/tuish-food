import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/cached_image.dart';
import 'package:tuish_food/core/widgets/price_tag.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/features/customer/cart/domain/entities/cart_item.dart';
import 'package:tuish_food/features/customer/cart/presentation/providers/cart_provider.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_item.dart';
import 'package:tuish_food/features/customer/menu/presentation/widgets/customization_selector.dart';

class ItemDetailBottomSheet extends ConsumerStatefulWidget {
  const ItemDetailBottomSheet({
    super.key,
    required this.item,
    required this.restaurantId,
    required this.restaurantName,
  });

  final MenuItem item;
  final String restaurantId;
  final String restaurantName;

  static Future<void> show(
    BuildContext context, {
    required MenuItem item,
    required String restaurantId,
    required String restaurantName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ItemDetailBottomSheet(
        item: item,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
      ),
    );
  }

  @override
  ConsumerState<ItemDetailBottomSheet> createState() =>
      _ItemDetailBottomSheetState();
}

class _ItemDetailBottomSheetState extends ConsumerState<ItemDetailBottomSheet> {
  int _quantity = 1;
  final Map<String, Set<String>> _selectedCustomizations = {};

  @override
  void initState() {
    super.initState();
    // Initialize required customizations
    for (final customization in widget.item.customizations) {
      _selectedCustomizations[customization.id] = {};
    }
  }

  double get _customizationTotal {
    double total = 0;
    for (final customization in widget.item.customizations) {
      final selected = _selectedCustomizations[customization.id] ?? {};
      for (final option in customization.options) {
        if (selected.contains(option.id)) {
          total += option.additionalPrice;
        }
      }
    }
    return total;
  }

  double get _totalPrice =>
      (widget.item.effectivePrice + _customizationTotal) * _quantity;

  bool get _allRequiredSelected {
    for (final customization in widget.item.customizations) {
      if (customization.required) {
        final selected = _selectedCustomizations[customization.id] ?? {};
        if (selected.isEmpty) return false;
      }
    }
    return true;
  }

  Map<String, List<String>> get _selectedCustomizationsForCart {
    final result = <String, List<String>>{};
    for (final entry in _selectedCustomizations.entries) {
      if (entry.value.isNotEmpty) {
        result[entry.key] = entry.value.toList();
      }
    }
    return result;
  }

  void _addToCart() {
    if (!_allRequiredSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all required customizations'),
        ),
      );
      return;
    }

    final cartItem = CartItem(
      menuItemId: widget.item.id,
      name: widget.item.name,
      imageUrl: widget.item.imageUrl,
      price: widget.item.effectivePrice + _customizationTotal,
      quantity: _quantity,
      selectedCustomizations: _selectedCustomizationsForCart,
    );

    ref
        .read(cartNotifierProvider.notifier)
        .addItem(
          cartItem,
          restaurantId: widget.restaurantId,
          restaurantName: widget.restaurantName,
          context: context,
        );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXL),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.s8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: AppSizes.borderRadiusPill,
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: AppSizes.paddingAllM,
                  children: [
                    // Image
                    if (item.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: AppSizes.borderRadiusM,
                        child: CachedImage(
                          imageUrl: item.imageUrl,
                          width: double.infinity,
                          height: 200,
                          borderRadius: AppSizes.borderRadiusM,
                        ),
                      ),
                    const SizedBox(height: AppSizes.s16),

                    // Veg indicator + Name
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: item.isVegetarian
                                  ? AppColors.vegGreen
                                  : AppColors.nonVegRed,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: item.isVegetarian
                                    ? AppColors.vegGreen
                                    : AppColors.nonVegRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.s8),
                        Expanded(
                          child: Text(
                            item.name,
                            style: AppTypography.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.s8),

                    // Price
                    PriceTag(
                      price: item.price,
                      discountedPrice: item.hasDiscount
                          ? item.discountedPrice
                          : null,
                    ),
                    const SizedBox(height: AppSizes.s8),

                    // Description
                    Text(
                      item.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s12),

                    // Tags row
                    Wrap(
                      spacing: AppSizes.s8,
                      runSpacing: AppSizes.s8,
                      children: [
                        if (item.isVegan)
                          _Tag(label: 'Vegan', color: AppColors.vegGreen),
                        if (item.isGlutenFree)
                          _Tag(label: 'Gluten Free', color: AppColors.info),
                        if (item.spiceLevel > 0)
                          _Tag(
                            label:
                                '${'🌶️' * item.spiceLevel.clamp(1, 3)} Spicy',
                            color: AppColors.error,
                          ),
                        _Tag(
                          label: '${item.preparationTimeMinutes} min',
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),

                    // Customizations
                    if (item.customizations.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.s24),
                      const Divider(),
                      const SizedBox(height: AppSizes.s8),
                      ...item.customizations.map((customization) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.s16),
                          child: CustomizationSelector(
                            customization: customization,
                            selectedOptionIds:
                                _selectedCustomizations[customization.id] ?? {},
                            onChanged: (selected) {
                              setState(() {
                                _selectedCustomizations[customization.id] =
                                    selected;
                              });
                            },
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: AppSizes.s16),
                  ],
                ),
              ),

              // Bottom bar: Quantity + Add to Cart
              Container(
                padding: const EdgeInsets.all(AppSizes.s16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Quantity selector
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
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.s8,
                              ),
                              child: Text(
                                '$_quantity',
                                style: AppTypography.titleSmall,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _quantity++),
                              icon: const Icon(Icons.add, size: 20),
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.s16),

                      // Add to cart button
                      Expanded(
                        child: TuishButton.primary(
                          label:
                              'Add to Cart - \u20B9${_totalPrice.toStringAsFixed(0)}',
                          onPressed: item.isAvailable ? _addToCart : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
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
