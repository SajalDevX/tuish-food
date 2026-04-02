import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/loading_overlay.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/core/widgets/tuish_text_field.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/providers/restaurant_owner_provider.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/screens/add_menu_item_screen.dart';

class EditMenuItemScreen extends ConsumerStatefulWidget {
  const EditMenuItemScreen({super.key, required this.itemId});

  final String itemId;

  @override
  ConsumerState<EditMenuItemScreen> createState() => _EditMenuItemScreenState();
}

class _EditMenuItemScreenState extends ConsumerState<EditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isVeg = true;
  bool _isAvailable = true;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _selectedCategory;

  static const _categories = menuCategoryOptions;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    final restaurantId = ref.read(myRestaurantIdProvider);
    if (restaurantId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menuItems')
          .doc(widget.itemId)
          .get();

      if (!doc.exists || !mounted) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final data = doc.data()!;
      _nameController.text = data['name'] as String? ?? '';
      _descriptionController.text = data['description'] as String? ?? '';
      _priceController.text = (data['price'] as num?)?.toString() ?? '';
      final discounted = data['discountedPrice'] as num?;
      if (discounted != null) {
        _discountedPriceController.text = discounted.toString();
      }
      _prepTimeController.text =
          (data['preparationTimeMinutes'] as num?)?.toString() ?? '';
      _imageUrlController.text = data['imageUrl'] as String? ?? '';
      _isVeg = data['isVegetarian'] as bool? ?? true;
      _isAvailable = data['isAvailable'] as bool? ?? true;
      _selectedCategory = data['categoryId'] as String?;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load item: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountedPriceController.dispose();
    _prepTimeController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final restaurantId = ref.read(myRestaurantIdProvider);
    if (restaurantId == null) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menuItems')
          .doc(widget.itemId)
          .update({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'categoryId': _selectedCategory,
        'price': double.parse(_priceController.text.trim()),
        if (_discountedPriceController.text.trim().isNotEmpty)
          'discountedPrice':
              double.parse(_discountedPriceController.text.trim())
        else
          'discountedPrice': FieldValue.delete(),
        'isVegetarian': _isVeg,
        'isAvailable': _isAvailable,
        'imageUrl': _imageUrlController.text.trim(),
        'preparationTimeMinutes':
            int.tryParse(_prepTimeController.text.trim()) ?? 15,
      });

      if (!mounted) return;
      ref.invalidate(myMenuItemsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menu item updated'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TuishAppBar(title: 'Edit Menu Item'),
      body: LoadingOverlay(
        isLoading: _isLoading || _isSaving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSizes.paddingAllL,
            children: [
              TuishTextField(
                controller: _nameController,
                label: 'Item Name',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: AppSizes.s12),
              TuishTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 3,
              ),
              const SizedBox(height: AppSizes.s12),
              Text('Category', style: AppTypography.labelLarge),
              const SizedBox(height: AppSizes.s8),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: AppSizes.borderRadiusM,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s16,
                    vertical: AppSizes.s12,
                  ),
                ),
                hint: const Text('Select category'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: AppSizes.s12),
              Row(
                children: [
                  Expanded(
                    child: TuishTextField(
                      controller: _priceController,
                      label: 'Price (\u20B9)',
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: TuishTextField(
                      controller: _discountedPriceController,
                      label: 'Discounted Price',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s12),
              TuishTextField(
                controller: _prepTimeController,
                label: 'Prep Time (minutes)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSizes.s12),
              TuishTextField(
                controller: _imageUrlController,
                label: 'Image URL',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: AppSizes.s16),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile.adaptive(
                      title: Text(_isVeg ? 'Vegetarian' : 'Non-Veg',
                          style: AppTypography.bodyLarge),
                      value: _isVeg,
                      activeTrackColor: AppColors.vegGreen,
                      onChanged: (v) => setState(() => _isVeg = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: SwitchListTile.adaptive(
                      title:
                          Text('Available', style: AppTypography.bodyLarge),
                      value: _isAvailable,
                      activeTrackColor: AppColors.success,
                      onChanged: (v) => setState(() => _isAvailable = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s32),
              TuishButton.primary(
                label: 'Save Changes',
                onPressed: _isSaving ? null : _saveItem,
                isLoading: _isSaving,
              ),
              const SizedBox(height: AppSizes.s24),
            ],
          ),
        ),
      ),
    );
  }
}
