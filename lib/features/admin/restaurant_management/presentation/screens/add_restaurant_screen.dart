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
import 'package:tuish_food/features/admin/restaurant_management/presentation/providers/restaurant_management_provider.dart';

class AddRestaurantScreen extends ConsumerStatefulWidget {
  const AddRestaurantScreen({super.key});

  @override
  ConsumerState<AddRestaurantScreen> createState() =>
      _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends ConsumerState<AddRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _deliveryFeeController = TextEditingController(text: '2.99');
  final _minOrderController = TextEditingController(text: '10.00');
  final _freeDeliveryController = TextEditingController(text: '30.00');
  final _prepTimeController = TextEditingController(text: '30');

  final List<String> _selectedCuisines = [];
  bool _isActive = true;

  static const _cuisineOptions = [
    'Italian',
    'Chinese',
    'Indian',
    'Mexican',
    'Japanese',
    'Thai',
    'American',
    'Mediterranean',
    'Korean',
    'Vietnamese',
    'French',
    'Greek',
    'Turkish',
    'Brazilian',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _imageUrlController.dispose();
    _deliveryFeeController.dispose();
    _minOrderController.dispose();
    _freeDeliveryController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCuisines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one cuisine')),
      );
      return;
    }

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'imageUrl': _imageUrlController.text.trim(),
      'coverImageUrl': '',
      'cuisineTypes': _selectedCuisines,
      'tags': [],
      'priceLevel': 2,
      'isActive': _isActive,
      'isOpen': false,
      'preparationTimeMinutes':
          int.tryParse(_prepTimeController.text) ?? 30,
      'minimumOrderAmount':
          double.tryParse(_minOrderController.text) ?? 10,
      'deliveryFee':
          double.tryParse(_deliveryFeeController.text) ?? 2.99,
      'freeDeliveryAbove':
          double.tryParse(_freeDeliveryController.text) ?? 30,
      'address': {
        'addressLine1': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'latitude': 0.0,
        'longitude': 0.0,
      },
      'operatingHours': _defaultOperatingHours(),
    };

    final success = await ref
        .read(restaurantCrudProvider.notifier)
        .createRestaurant(data);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant created successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  List<Map<String, dynamic>> _defaultOperatingHours() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days
        .map((day) => {
              'day': day,
              'openTime': '09:00',
              'closeTime': '22:00',
              'isClosed': false,
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final crudState = ref.watch(restaurantCrudProvider);
    final isLoading = crudState.isLoading;

    ref.listen<AsyncValue<void>>(restaurantCrudProvider, (_, state) {
      state.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        },
      );
    });

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        appBar: const TuishAppBar(title: 'Add Restaurant'),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: AppSizes.paddingAllM,
            children: [
              // Basic info section
              _SectionHeader(title: 'Basic Information'),
              const SizedBox(height: AppSizes.s12),
              TuishTextField(
                label: 'Restaurant Name',
                hint: 'Enter restaurant name',
                controller: _nameController,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Name is required' : null,
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
                      label: 'Phone',
                      hint: '+1 234 567 890',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: AppSizes.s16),
                  Expanded(
                    child: TuishTextField(
                      label: 'Email',
                      hint: 'email@restaurant.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s16),
              TuishTextField(
                label: 'Image URL',
                hint: 'https://...',
                controller: _imageUrlController,
              ),
              const SizedBox(height: AppSizes.s24),

              // Cuisines
              _SectionHeader(title: 'Cuisine Types'),
              const SizedBox(height: AppSizes.s12),
              Wrap(
                spacing: AppSizes.s8,
                runSpacing: AppSizes.s8,
                children: _cuisineOptions.map((cuisine) {
                  final isSelected = _selectedCuisines.contains(cuisine);
                  return FilterChip(
                    label: Text(cuisine),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSizes.borderRadiusPill,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCuisines.add(cuisine);
                        } else {
                          _selectedCuisines.remove(cuisine);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSizes.s24),

              // Address section
              _SectionHeader(title: 'Address'),
              const SizedBox(height: AppSizes.s12),
              TuishTextField(
                label: 'Street Address',
                hint: '123 Main St',
                controller: _addressController,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Address is required' : null,
              ),
              const SizedBox(height: AppSizes.s16),
              Row(
                children: [
                  Expanded(
                    child: TuishTextField(
                      label: 'City',
                      hint: 'City',
                      controller: _cityController,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: AppSizes.s16),
                  Expanded(
                    child: TuishTextField(
                      label: 'State',
                      hint: 'State',
                      controller: _stateController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s24),

              // Delivery settings
              _SectionHeader(title: 'Delivery Settings'),
              const SizedBox(height: AppSizes.s12),
              Row(
                children: [
                  Expanded(
                    child: TuishTextField(
                      label: 'Delivery Fee (\$)',
                      hint: '2.99',
                      controller: _deliveryFeeController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppSizes.s16),
                  Expanded(
                    child: TuishTextField(
                      label: 'Min Order (\$)',
                      hint: '10.00',
                      controller: _minOrderController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s16),
              Row(
                children: [
                  Expanded(
                    child: TuishTextField(
                      label: 'Free Delivery Above (\$)',
                      hint: '30.00',
                      controller: _freeDeliveryController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppSizes.s16),
                  Expanded(
                    child: TuishTextField(
                      label: 'Prep Time (min)',
                      hint: '30',
                      controller: _prepTimeController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s24),

              // Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active Status', style: AppTypography.labelLarge),
                  Switch.adaptive(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeTrackColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s32),

              TuishButton.primary(
                label: 'Create Restaurant',
                onPressed: isLoading ? null : _submit,
                isLoading: isLoading,
              ),
              const SizedBox(height: AppSizes.s32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        color: AppColors.primary,
      ),
    );
  }
}
