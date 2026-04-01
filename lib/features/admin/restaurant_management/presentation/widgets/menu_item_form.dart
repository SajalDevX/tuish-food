import 'package:flutter/material.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/core/widgets/tuish_text_field.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_item.dart';

class MenuItemForm extends StatefulWidget {
  const MenuItemForm({
    super.key,
    this.menuItem,
    required this.onSubmit,
    this.isLoading = false,
  });

  final MenuItem? menuItem;
  final void Function(Map<String, dynamic> data) onSubmit;
  final bool isLoading;

  @override
  State<MenuItemForm> createState() => _MenuItemFormState();
}

class _MenuItemFormState extends State<MenuItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _categoryController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _prepTimeController;
  late bool _isVegetarian;
  late bool _isVegan;
  late bool _isAvailable;
  late bool _isPopular;
  late int _spiceLevel;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.menuItem?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.menuItem?.description ?? '');
    _priceController = TextEditingController(
        text: widget.menuItem?.price.toStringAsFixed(2) ?? '');
    _categoryController =
        TextEditingController(text: widget.menuItem?.categoryId ?? '');
    _imageUrlController =
        TextEditingController(text: widget.menuItem?.imageUrl ?? '');
    _prepTimeController = TextEditingController(
        text: widget.menuItem?.preparationTimeMinutes.toString() ?? '15');
    _isVegetarian = widget.menuItem?.isVegetarian ?? false;
    _isVegan = widget.menuItem?.isVegan ?? false;
    _isAvailable = widget.menuItem?.isAvailable ?? true;
    _isPopular = widget.menuItem?.isPopular ?? false;
    _spiceLevel = widget.menuItem?.spiceLevel ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.tryParse(_priceController.text) ?? 0,
      'categoryId': _categoryController.text.trim(),
      'imageUrl': _imageUrlController.text.trim(),
      'preparationTimeMinutes':
          int.tryParse(_prepTimeController.text) ?? 15,
      'isVegetarian': _isVegetarian,
      'isVegan': _isVegan,
      'isGlutenFree': false,
      'isAvailable': _isAvailable,
      'isPopular': _isPopular,
      'spiceLevel': _spiceLevel,
      'sortOrder': widget.menuItem?.sortOrder ?? 0,
      'customizations': [],
    };

    widget.onSubmit(data);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: AppSizes.paddingAllM,
        children: [
          TuishTextField(
            label: 'Item Name',
            hint: 'Enter item name',
            controller: _nameController,
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: AppSizes.s16),
          TuishTextField(
            label: 'Description',
            hint: 'Enter description',
            controller: _descriptionController,
            maxLines: 3,
          ),
          const SizedBox(height: AppSizes.s16),
          Row(
            children: [
              Expanded(
                child: TuishTextField(
                  label: 'Price (\$)',
                  hint: '0.00',
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
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
                  label: 'Prep Time (min)',
                  hint: '15',
                  controller: _prepTimeController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s16),
          TuishTextField(
            label: 'Category ID',
            hint: 'Enter category',
            controller: _categoryController,
            validator: (value) => (value == null || value.isEmpty)
                ? 'Category is required'
                : null,
          ),
          const SizedBox(height: AppSizes.s16),
          TuishTextField(
            label: 'Image URL',
            hint: 'Enter image URL',
            controller: _imageUrlController,
          ),
          const SizedBox(height: AppSizes.s24),

          // Spice level
          Text('Spice Level', style: AppTypography.labelLarge),
          const SizedBox(height: AppSizes.s8),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _spiceLevel = index + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSizes.s4),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: index < _spiceLevel
                        ? AppColors.error
                        : AppColors.textHint,
                    size: 28,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSizes.s24),

          // Toggles
          _buildSwitch('Vegetarian', _isVegetarian, (v) {
            setState(() => _isVegetarian = v);
          }),
          _buildSwitch('Vegan', _isVegan, (v) {
            setState(() => _isVegan = v);
          }),
          _buildSwitch('Available', _isAvailable, (v) {
            setState(() => _isAvailable = v);
          }),
          _buildSwitch('Popular', _isPopular, (v) {
            setState(() => _isPopular = v);
          }),
          const SizedBox(height: AppSizes.s32),
          TuishButton.primary(
            label: widget.menuItem != null ? 'Update Item' : 'Add Item',
            onPressed: widget.isLoading ? null : _submit,
            isLoading: widget.isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
