import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/image_picker_field.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_text_field.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/features/admin/restaurant_management/presentation/providers/restaurant_management_provider.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/providers/restaurant_owner_provider.dart';

/// Available categories for menu items. Shared across add/edit screens.
const menuCategoryOptions = <String>[
  'Starters',
  'Main Course',
  'Biryani',
  'Pizzas',
  'Pasta',
  'Breads',
  'Rice',
  'Dosas',
  'Idli & Vada',
  'Meals',
  'Desserts',
  'Beverages',
  'Sides',
  'Combos',
];

class AddMenuItemScreen extends ConsumerStatefulWidget {
  const AddMenuItemScreen({super.key});

  @override
  ConsumerState<AddMenuItemScreen> createState() => _AddMenuItemScreenState();
}

class _AddMenuItemScreenState extends ConsumerState<AddMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _prepTimeController = TextEditingController();

  String? _selectedCategory;
  String? _imageUrl;
  bool _isVeg = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountedPriceController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final restaurantId = ref.read(myRestaurantIdProvider);
    if (restaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No restaurant found. Set up first.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'categoryId': _selectedCategory,
        'price': double.parse(_priceController.text.trim()),
        if (_discountedPriceController.text.trim().isNotEmpty)
          'discountedPrice':
              double.parse(_discountedPriceController.text.trim()),
        'isVegetarian': _isVeg,
        'isAvailable': true,
        'isPopular': false,
        'imageUrl': _imageUrl ?? '',
        'preparationTimeMinutes':
            int.tryParse(_prepTimeController.text.trim()) ?? 15,
        'sortOrder': 0,
        'customizations': [],
      };

      final repo = ref.read(adminRestaurantRepositoryProvider);
      final result = await repo.addMenuItem(restaurantId, data);

      if (!mounted) return;

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: ${failure.message}'),
              backgroundColor: AppColors.error,
            ),
          );
        },
        (_) {
          ref.invalidate(myMenuItemsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menu item added successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TuishAppBar(title: 'Add Menu Item'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSizes.paddingAllM,
          children: [
            TuishTextField(
              label: 'Item Name',
              hint: 'e.g. Paneer Butter Masala',
              controller: _nameController,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Item name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.s16),

            TuishTextField(
              label: 'Description',
              hint: 'Describe the dish...',
              controller: _descriptionController,
              maxLines: 3,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.s16),

            // Category dropdown
            Text('Category', style: AppTypography.labelLarge),
            const SizedBox(height: AppSizes.s8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _selectedCategory,
              decoration: InputDecoration(
                hintText: 'Select a category',
                hintStyle: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textHint,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s16,
                  vertical: AppSizes.s16,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppSizes.borderRadiusM,
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppSizes.borderRadiusM,
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppSizes.borderRadiusM,
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
              items: menuCategoryOptions
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat, style: AppTypography.bodyLarge),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
              validator: (value) {
                if (value == null) return 'Please select a category';
                return null;
              },
            ),
            const SizedBox(height: AppSizes.s16),

            // Price row
            Row(
              children: [
                Expanded(
                  child: TuishTextField(
                    label: 'Price (\u20B9)',
                    hint: '249',
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Price is required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.s16),
                Expanded(
                  child: TuishTextField(
                    label: 'Discounted Price (optional)',
                    hint: '199',
                    controller: _discountedPriceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Invalid price';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s16),

            // Veg / Non-veg toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isVeg
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
                            color: _isVeg
                                ? AppColors.vegGreen
                                : AppColors.nonVegRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    Text(
                      _isVeg ? 'Vegetarian' : 'Non-Vegetarian',
                      style: AppTypography.labelLarge.copyWith(
                        color: _isVeg
                            ? AppColors.vegGreen
                            : AppColors.nonVegRed,
                      ),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: _isVeg,
                  activeTrackColor: AppColors.vegGreen,
                  inactiveTrackColor:
                      AppColors.nonVegRed.withValues(alpha: 0.3),
                  onChanged: (value) => setState(() => _isVeg = value),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s16),

            Text('Item Photo', style: AppTypography.labelLarge),
            const SizedBox(height: AppSizes.s8),
            ImagePickerField(
              imageUrl: _imageUrl,
              storagePath: () {
                final restaurantId =
                    ref.read(myRestaurantIdProvider) ?? 'unknown';
                return 'restaurants/$restaurantId/menu_items/${DateTime.now().millisecondsSinceEpoch}.jpg';
              },
              label: 'Add Photo',
              isCircle: false,
              aspectRatio: 1.0,
              onUploaded: (url) =>
                  setState(() => _imageUrl = url.isEmpty ? null : url),
            ),
            const SizedBox(height: AppSizes.s16),

            TuishTextField(
              label: 'Prep Time (minutes)',
              hint: '20',
              controller: _prepTimeController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Prep time is required';
                }
                if (int.tryParse(value) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.s32),

            TuishButton.primary(
              label: 'Save Menu Item',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _onSave,
            ),
            const SizedBox(height: AppSizes.s16),
          ],
        ),
      ),
    );
  }
}
