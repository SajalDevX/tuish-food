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
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';

class EditRestaurantScreen extends ConsumerStatefulWidget {
  const EditRestaurantScreen({
    super.key,
    required this.restaurantId,
  });

  final String restaurantId;

  @override
  ConsumerState<EditRestaurantScreen> createState() =>
      _EditRestaurantScreenState();
}

class _EditRestaurantScreenState extends ConsumerState<EditRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _imageUrlController;
  late TextEditingController _deliveryFeeController;
  late TextEditingController _minOrderController;
  late TextEditingController _freeDeliveryController;
  late TextEditingController _prepTimeController;

  List<String> _selectedCuisines = [];
  bool _isActive = true;
  bool _initialized = false;

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
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _imageUrlController = TextEditingController();
    _deliveryFeeController = TextEditingController();
    _minOrderController = TextEditingController();
    _freeDeliveryController = TextEditingController();
    _prepTimeController = TextEditingController();
  }

  void _populateFields(Restaurant restaurant) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = restaurant.name;
    _descriptionController.text = restaurant.description;
    _addressController.text = restaurant.address.addressLine1;
    _cityController.text = restaurant.address.city;
    _stateController.text = restaurant.address.state;
    _imageUrlController.text = restaurant.imageUrl;
    _deliveryFeeController.text = restaurant.deliveryFee.toStringAsFixed(2);
    _minOrderController.text =
        restaurant.minimumOrderAmount.toStringAsFixed(2);
    _freeDeliveryController.text =
        restaurant.freeDeliveryAbove.toStringAsFixed(2);
    _prepTimeController.text =
        restaurant.preparationTimeMinutes.toString();
    _selectedCuisines = List<String>.from(restaurant.cuisineTypes);
    _isActive = restaurant.isActive;
  }

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

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'imageUrl': _imageUrlController.text.trim(),
      'cuisineTypes': _selectedCuisines,
      'isActive': _isActive,
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
    };

    final success = await ref
        .read(restaurantCrudProvider.notifier)
        .updateRestaurant(widget.restaurantId, data);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(allRestaurantsProvider);
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

    return restaurantsAsync.when(
      data: (restaurants) {
        final restaurant = restaurants.where(
          (r) => r.id == widget.restaurantId,
        );

        if (restaurant.isEmpty) {
          return Scaffold(
            appBar: const TuishAppBar(title: 'Edit Restaurant'),
            body: Center(
              child: Text(
                'Restaurant not found',
                style: AppTypography.bodyLarge,
              ),
            ),
          );
        }

        _populateFields(restaurant.first);

        return LoadingOverlay(
          isLoading: isLoading,
          child: Scaffold(
            appBar: const TuishAppBar(title: 'Edit Restaurant'),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: AppSizes.paddingAllM,
                children: [
                  _SectionHeader(title: 'Basic Information'),
                  const SizedBox(height: AppSizes.s12),
                  TuishTextField(
                    label: 'Restaurant Name',
                    hint: 'Enter restaurant name',
                    controller: _nameController,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Name is required'
                        : null,
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

                  _SectionHeader(title: 'Cuisine Types'),
                  const SizedBox(height: AppSizes.s12),
                  Wrap(
                    spacing: AppSizes.s8,
                    runSpacing: AppSizes.s8,
                    children: _cuisineOptions.map((cuisine) {
                      final isSelected =
                          _selectedCuisines.contains(cuisine);
                      return FilterChip(
                        label: Text(cuisine),
                        selected: isSelected,
                        selectedColor:
                            AppColors.primary.withValues(alpha: 0.2),
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

                  _SectionHeader(title: 'Address'),
                  const SizedBox(height: AppSizes.s12),
                  TuishTextField(
                    label: 'Street Address',
                    hint: '123 Main St',
                    controller: _addressController,
                  ),
                  const SizedBox(height: AppSizes.s16),
                  Row(
                    children: [
                      Expanded(
                        child: TuishTextField(
                          label: 'City',
                          hint: 'City',
                          controller: _cityController,
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

                  _SectionHeader(title: 'Delivery Settings'),
                  const SizedBox(height: AppSizes.s12),
                  Row(
                    children: [
                      Expanded(
                        child: TuishTextField(
                          label: 'Delivery Fee (\$)',
                          controller: _deliveryFeeController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppSizes.s16),
                      Expanded(
                        child: TuishTextField(
                          label: 'Min Order (\$)',
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
                          controller: _freeDeliveryController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppSizes.s16),
                      Expanded(
                        child: TuishTextField(
                          label: 'Prep Time (min)',
                          controller: _prepTimeController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.s24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Active Status',
                          style: AppTypography.labelLarge),
                      Switch.adaptive(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeTrackColor: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.s32),

                  TuishButton.primary(
                    label: 'Update Restaurant',
                    onPressed: isLoading ? null : _submit,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: AppSizes.s32),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        appBar: const TuishAppBar(title: 'Edit Restaurant'),
        body: Center(child: Text('Error: $error')),
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
