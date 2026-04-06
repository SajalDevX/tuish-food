import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore, GeoPoint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:tuish_food/core/constants/api_constants.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/glass_scaffold.dart';
import 'package:tuish_food/core/widgets/image_picker_field.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_text_field.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/providers/restaurant_owner_provider.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/providers/subscription_provider.dart';
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
  static const int _maxSteps = 4;
  final _formKeys = List.generate(_maxSteps, (_) => GlobalKey<FormState>());
  final _pageController = PageController();
  int _currentStep = 0;

  // Razorpay
  late final Razorpay _razorpay;
  String? _createdRestaurantId;

  // Step 1: Basic info
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final Set<String> _selectedCuisines = {};
  String? _imageUrl;
  String? _coverImageUrl;
  late final String _ownerUid;

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

  bool _isEditMode = false;
  int get _totalSteps => _isEditMode ? 3 : 4;

  @override
  void initState() {
    super.initState();
    _ownerUid = ref.read(currentUserProvider)?.uid ?? '';
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // If editing an existing restaurant, populate the form fields
    final restaurant = ref.read(myRestaurantProvider).value;
    if (restaurant != null) {
      _isEditMode = true;
      _createdRestaurantId = restaurant.id;
      _nameController.text = restaurant.name;
      _descriptionController.text = restaurant.description;
      _imageUrl = restaurant.imageUrl.isEmpty ? null : restaurant.imageUrl;
      _coverImageUrl =
          restaurant.coverImageUrl.isEmpty ? null : restaurant.coverImageUrl;
      _selectedCuisines.addAll(restaurant.cuisineTypes);
      _streetController.text = restaurant.address.addressLine1;
      _cityController.text = restaurant.address.city;
      _stateController.text = restaurant.address.state;
      _deliveryFeeController.text =
          restaurant.deliveryFee.toStringAsFixed(0);
      _minOrderController.text =
          restaurant.minimumOrderAmount.toStringAsFixed(0);
      if (restaurant.freeDeliveryAbove > 0) {
        _freeDeliveryAboveController.text =
            restaurant.freeDeliveryAbove.toStringAsFixed(0);
      }
      _prepTimeController.text =
          restaurant.preparationTimeMinutes.toString();
      _isActive = restaurant.isActive;
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
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
    if (step < 0 || step >= _totalSteps) return;

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

  /// Creates the restaurant in Firestore (hidden until subscription activates),
  /// then creates a Razorpay subscription and opens the checkout.
  Future<void> _onSubscribeAndCreate() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Prevent creating a second restaurant
    final existing = ref.read(myRestaurantProvider).value;
    if (existing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already have a restaurant.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Create restaurant with isSubscriptionValid: false
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'cuisineTypes': _selectedCuisines.toList(),
        'tags': _selectedCuisines.map((c) => c.toLowerCase()).toList(),
        'ownerUid': user.uid,
        'address': await _buildAddress(),
        'deliveryFee': double.tryParse(_deliveryFeeController.text) ?? 0,
        'minimumOrderAmount': double.tryParse(_minOrderController.text) ?? 0,
        'freeDeliveryAbove':
            double.tryParse(_freeDeliveryAboveController.text) ?? 0,
        'preparationTimeMinutes':
            int.tryParse(_prepTimeController.text) ?? 30,
        'isActive': _isActive,
        'isOpen': _isActive,
        'imageUrl': _imageUrl ?? '',
        'coverImageUrl': _coverImageUrl ?? '',
        'priceLevel': 1,
        'isSubscriptionValid': false,
        'subscriptionStatus': 'none',
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

      _createdRestaurantId = await createRestaurant(ref, data: data);
      if (!mounted || _createdRestaurantId == null) return;

      // 2. Create Razorpay subscription via Cloud Function
      final subscriptionId = await createSubscription(
        ref,
        restaurantId: _createdRestaurantId!,
      );

      // 3. Open Razorpay checkout for subscription
      _razorpay.open({
        'key': ApiConstants.razorpayKeyId,
        'subscription_id': subscriptionId,
        'name': 'Tuish Food',
        'description': 'Restaurant Monthly Subscription',
        'theme': {'color': '#FF6B35'},
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Save changes to an existing restaurant (edit mode).
  Future<void> _onSaveChanges() async {
    if (!_formKeys[_currentStep].currentState!.validate()) return;
    if (_createdRestaurantId == null) return;

    setState(() => _isSubmitting = true);

    try {
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'cuisineTypes': _selectedCuisines.toList(),
        'tags': _selectedCuisines.map((c) => c.toLowerCase()).toList(),
        'address': await _buildAddress(),
        'deliveryFee': double.tryParse(_deliveryFeeController.text) ?? 0,
        'minimumOrderAmount': double.tryParse(_minOrderController.text) ?? 0,
        'freeDeliveryAbove':
            double.tryParse(_freeDeliveryAboveController.text) ?? 0,
        'preparationTimeMinutes':
            int.tryParse(_prepTimeController.text) ?? 30,
        'isActive': _isActive,
        'isOpen': _isActive,
        'imageUrl': _imageUrl ?? '',
        'coverImageUrl': _coverImageUrl ?? '',
      };

      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(_createdRestaurantId!)
          .update(data);

      ref.invalidate(myRestaurantProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant updated!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;

    // Optimistically mark subscription as active (webhook may be delayed)
    if (_createdRestaurantId != null) {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(_createdRestaurantId!)
          .update({
        'subscriptionStatus': 'active',
        'isSubscriptionValid': true,
      });
    }

    ref.invalidate(myRestaurantProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Subscription activated! Welcome to Tuish Food.'),
        backgroundColor: AppColors.success,
      ),
    );
    context.go(RoutePaths.restaurantDashboard);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment failed. You can subscribe later from your profile. '
          '${response.message ?? ''}',
        ),
        backgroundColor: AppColors.error,
      ),
    );
    // Restaurant was created but hidden — owner can subscribe from profile
    context.go(RoutePaths.restaurantDashboard);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // External wallet selected — payment will complete asynchronously
  }

  Future<Map<String, dynamic>> _buildAddress() async {
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    double latitude = 0.0;
    double longitude = 0.0;

    try {
      final locations = await geocoding.locationFromAddress(
        '$street, $city, $state',
      );
      if (locations.isNotEmpty) {
        latitude = locations.first.latitude;
        longitude = locations.first.longitude;
      }
    } catch (_) {
      // Geocoding failed — keep 0,0 as fallback
    }

    return {
      'addressLine1': street,
      'city': city,
      'state': state,
      'location': GeoPoint(latitude, longitude),
    };
  }

  // ---------------------------------------------------------------------------
  // Step builders
  // ---------------------------------------------------------------------------

  Widget _buildStepIndicator() {
    final labels = _isEditMode
        ? ['Info', 'Address', 'Operations']
        : ['Info', 'Address', 'Operations', 'Subscribe'];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s16,
        vertical: AppSizes.s12,
      ),
      child: Row(
        children: List.generate(_totalSteps, (index) {
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
                if (index < _totalSteps - 1 && index > 0)
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

          // Restaurant logo
          Text('Restaurant Logo', style: AppTypography.labelLarge),
          const SizedBox(height: AppSizes.s8),
          Center(
            child: ImagePickerField(
              imageUrl: _imageUrl,
              storagePath: () =>
                  'restaurants/$_ownerUid/logo_${DateTime.now().millisecondsSinceEpoch}.jpg',
              label: 'Add Logo',
              isCircle: true,
              onUploaded: (url) =>
                  setState(() => _imageUrl = url.isEmpty ? null : url),
            ),
          ),
          const SizedBox(height: AppSizes.s16),

          // Cover image
          Text('Cover Image', style: AppTypography.labelLarge),
          const SizedBox(height: AppSizes.s8),
          ImagePickerField(
            imageUrl: _coverImageUrl,
            storagePath: () =>
                'restaurants/$_ownerUid/cover_${DateTime.now().millisecondsSinceEpoch}.jpg',
            label: 'Add Cover Photo',
            isCircle: false,
            aspectRatio: 16 / 9,
            onUploaded: (url) =>
                setState(() => _coverImageUrl = url.isEmpty ? null : url),
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

  Widget _buildStep4Subscribe() {
    return Form(
      key: _formKeys[3],
      child: ListView(
        padding: AppSizes.paddingAllM,
        children: [
          const SizedBox(height: AppSizes.s16),
          Icon(
            Icons.workspace_premium_rounded,
            size: 64,
            color: AppColors.warning,
          ),
          const SizedBox(height: AppSizes.s16),
          Text(
            'Activate Your Restaurant',
            style: AppTypography.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.s8),
          Text(
            'Subscribe to make your restaurant visible to customers '
            'and start receiving orders.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.s32),
          Container(
            padding: const EdgeInsets.all(AppSizes.s24),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary),
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
            ),
            child: Column(
              children: [
                Text(
                  'Monthly Plan',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSizes.s8),
                Text(
                  'Auto-renews monthly. Cancel anytime.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.s16),
                const Divider(),
                const SizedBox(height: AppSizes.s12),
                _buildPlanFeature(Icons.storefront, 'Listed on Tuish Food'),
                _buildPlanFeature(Icons.shopping_bag, 'Receive customer orders'),
                _buildPlanFeature(Icons.analytics, 'Dashboard & analytics'),
                _buildPlanFeature(Icons.delivery_dining, 'Delivery partner matching'),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.s24),
          Text(
            'You can also subscribe later from your restaurant profile.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.success),
          const SizedBox(width: AppSizes.s12),
          Text(text, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation buttons
  // ---------------------------------------------------------------------------

  Widget _buildNavigationButtons() {
    final isFirstStep = _currentStep == 0;
    final isLastStep = _currentStep == _totalSteps - 1;

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
                    label: _isEditMode ? 'Save Changes' : 'Subscribe & Create',
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting
                        ? null
                        : _isEditMode
                            ? _onSaveChanges
                            : _onSubscribeAndCreate,
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
    return GlassScaffold(
      appBar: TuishAppBar(title: _isEditMode ? 'Edit Restaurant' : 'Restaurant Setup'),
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
                if (!_isEditMode) _buildStep4Subscribe(),
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
