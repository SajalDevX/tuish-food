import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_text_field.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/providers/restaurant_owner_provider.dart';
import 'package:tuish_food/injection_container.dart';
import 'package:tuish_food/routing/route_paths.dart';

/// Available cuisine types for restaurant setup.
const _cuisineOptions = <String>[
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
  'Middle Eastern',
  'South Indian',
  'Biryani',
  'Pizza',
];

class RestaurantSetupScreen extends ConsumerStatefulWidget {
  const RestaurantSetupScreen({super.key});

  @override
  ConsumerState<RestaurantSetupScreen> createState() =>
      _RestaurantSetupScreenState();
}

class _RestaurantSetupScreenState extends ConsumerState<RestaurantSetupScreen> {
  final _formKeys = List.generate(3, (_) => GlobalKey<FormState>());
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Basic info
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final Set<String> _selectedCuisines = {};

  // Step 2: Address
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  // Step 3: Delivery & operations
  final _deliveryFeeController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _freeDeliveryAboveController = TextEditingController();
  final _prepTimeController = TextEditingController();
  bool _isActive = true;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _deliveryFeeController.dispose();
    _minOrderController.dispose();
    _freeDeliveryAboveController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step > 2) return;

    // Validate current step before moving forward.
    if (step > _currentStep) {
      if (!_formKeys[_currentStep].currentState!.validate()) return;
      if (_currentStep == 0 && _selectedCuisines.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one cuisine')),
        );
        return;
      }
    }

    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKeys[_currentStep].currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'cuisineTypes': _selectedCuisines.toList(),
        'tags': _selectedCuisines.map((c) => c.toLowerCase()).toList(),
        'ownerUid': user.uid,
        'address': {
          'addressLine1': _streetController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'latitude': 0.0,
          'longitude': 0.0,
        },
        'deliveryFee': double.tryParse(_deliveryFeeController.text) ?? 0,
        'minimumOrderAmount': double.tryParse(_minOrderController.text) ?? 0,
        'freeDeliveryAbove':
            double.tryParse(_freeDeliveryAboveController.text) ?? 0,
        'preparationTimeMinutes':
            int.tryParse(_prepTimeController.text) ?? 30,
        'isActive': _isActive,
        'isOpen': _isActive,
        'imageUrl': '',
        'coverImageUrl': '',
        'priceLevel': 1,
        'operatingHours': List.generate(7, (i) {
          const days = [
            'Monday', 'Tuesday', 'Wednesday', 'Thursday',
            'Friday', 'Saturday', 'Sunday',
          ];
          return {
            'day': days[i],
            'openTime': '09:00',
            'closeTime': '22:00',
            'isClosed': false,
          };
        }),
      };

      await createRestaurant(ref, data: data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      context.go(RoutePaths.restaurantDashboard);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create restaurant: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Step builders
  // ---------------------------------------------------------------------------

  Widget _buildStepIndicator() {
    const labels = ['Basic Info', 'Address', 'Operations'];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s16,
        vertical: AppSizes.s12,
      ),
      child: Row(
        children: List.generate(3, (index) {
          final isCompleted = index < _currentStep;
          final isActive = index == _currentStep;
          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted || isActive
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isCompleted
                          ? AppColors.success
                          : isActive
                              ? AppColors.primary
                              : AppColors.divider,
                      child: isCompleted
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: AppTypography.labelMedium.copyWith(
                                color: isActive
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                    ),
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      labels[index],
                      style: AppTypography.labelSmall.copyWith(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                if (index < 2 && index > 0)
                  const SizedBox.shrink()
                else if (index == 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _currentStep > 0
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1BasicInfo() {
    return Form(
      key: _formKeys[0],
      child: ListView(
        padding: AppSizes.paddingAllM,
        children: [
          TuishTextField(
            label: 'Restaurant Name',
            hint: 'e.g. Spice Garden',
            controller: _nameController,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Restaurant name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.s16),
          TuishTextField(
            label: 'Description',
            hint: 'Tell customers about your restaurant...',
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
          TuishTextField(
            label: 'Phone',
            hint: '+91 98765 43210',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.s16),
          TuishTextField(
            label: 'Email',
            hint: 'owner@restaurant.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$')
                  .hasMatch(value)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.s24),
          Text('Cuisine Types', style: AppTypography.labelLarge),
          const SizedBox(height: AppSizes.s8),
          Wrap(
            spacing: AppSizes.s8,
            runSpacing: AppSizes.s8,
            children: _cuisineOptions.map((cuisine) {
              final isSelected = _selectedCuisines.contains(cuisine);
              return FilterChip(
                label: Text(cuisine),
                selected: isSelected,
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: AppTypography.bodyMedium.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.divider,
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
          if (_selectedCuisines.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.s8),
              child: Text(
                'Select at least one cuisine type',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep2Address() {
    return Form(
      key: _formKeys[1],
      child: ListView(
        padding: AppSizes.paddingAllM,
        children: [
          Text(
            'Where is your restaurant located?',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSizes.s24),
          TuishTextField(
            label: 'Street Address',
            hint: '123 Main Street',
            controller: _streetController,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Street address is required';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.s16),
          TuishTextField(
            label: 'City',
            hint: 'Mumbai',
            controller: _cityController,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'City is required';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.s16),
          TuishTextField(
            label: 'State',
            hint: 'Maharashtra',
            controller: _stateController,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'State is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Operations() {
    return Form(
      key: _formKeys[2],
      child: ListView(
        padding: AppSizes.paddingAllM,
        children: [
          Text(
            'Set up your delivery and operations',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSizes.s24),
          TuishTextField(
            label: 'Delivery Fee (\u20B9)',
            hint: '30',
            controller: _deliveryFeeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Delivery fee is required';
              }
              if (double.tryParse(value) == null) {
                return 'Enter a valid amount';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.s16),
          TuishTextField(
            label: 'Minimum Order (\u20B9)',
            hint: '99',
            controller: _minOrderController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Minimum order amount is required';
              }
              if (double.tryParse(value) == null) {
                return 'Enter a valid amount';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.s16),
          TuishTextField(
            label: 'Free Delivery Above (\u20B9) — optional',
            hint: '499',
            controller: _freeDeliveryAboveController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                if (double.tryParse(value) == null) {
                  return 'Enter a valid amount';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.s16),
          TuishTextField(
            label: 'Average Prep Time (minutes)',
            hint: '30',
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
          const SizedBox(height: AppSizes.s24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Restaurant Active', style: AppTypography.labelLarge),
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      'Start accepting orders immediately',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isActive,
                activeTrackColor: AppColors.primary,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation buttons
  // ---------------------------------------------------------------------------

  Widget _buildNavigationButtons() {
    final isFirstStep = _currentStep == 0;
    final isLastStep = _currentStep == 2;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.s16),
      child: Row(
        children: [
          if (!isFirstStep)
            Expanded(
              child: TuishButton.outlined(
                label: 'Back',
                onPressed: () => _goToStep(_currentStep - 1),
              ),
            ),
          if (!isFirstStep) const SizedBox(width: AppSizes.s16),
          Expanded(
            child: isLastStep
                ? TuishButton.primary(
                    label: 'Submit',
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _onSubmit,
                  )
                : TuishButton.primary(
                    label: 'Next',
                    onPressed: () => _goToStep(_currentStep + 1),
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TuishAppBar(title: 'Restaurant Setup'),
      body: Column(
        children: [
          _buildStepIndicator(),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1BasicInfo(),
                _buildStep2Address(),
                _buildStep3Operations(),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          _buildNavigationButtons(),
        ],
      ),
    );
  }
}
