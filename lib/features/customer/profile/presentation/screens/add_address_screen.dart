import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/core/widgets/tuish_text_field.dart';
import 'package:tuish_food/features/customer/profile/domain/entities/address.dart';
import 'package:tuish_food/features/customer/profile/presentation/providers/profile_provider.dart';
import 'package:tuish_food/injection_container.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  const AddAddressScreen({super.key});

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  String _selectedLabel = 'Home';
  final _customLabelController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;

  static const _labels = ['Home', 'Work', 'Other'];

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _customLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TuishAppBar(title: 'Add Address'),
      body: SingleChildScrollView(
        padding: AppSizes.paddingAllM,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label selector
              Text('Address Label', style: AppTypography.labelLarge),
              const SizedBox(height: AppSizes.s12),
              Wrap(
                spacing: AppSizes.s8,
                children: _labels.map((label) {
                  final isSelected = _selectedLabel == label;
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.textPrimary,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedLabel = label);
                      }
                    },
                  );
                }).toList(),
              ),

              // Custom label for "Other"
              if (_selectedLabel == 'Other') ...[
                const SizedBox(height: AppSizes.s16),
                TuishTextField(
                  label: 'Custom Label',
                  hint: 'e.g., Parent\'s Home',
                  controller: _customLabelController,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (_selectedLabel == 'Other' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Please enter a label';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: AppSizes.s20),

              // Address line 1
              TuishTextField(
                label: 'Address Line 1',
                hint: 'Street address, building, etc.',
                controller: _addressLine1Controller,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSizes.s20),

              // Address line 2
              TuishTextField(
                label: 'Address Line 2 (Optional)',
                hint: 'Apartment, floor, landmark',
                controller: _addressLine2Controller,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: AppSizes.s20),

              // City
              TuishTextField(
                label: 'City',
                hint: 'City',
                controller: _cityController,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'City is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSizes.s20),

              // State and Zip code in a row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TuishTextField(
                      label: 'State',
                      hint: 'State',
                      controller: _stateController,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSizes.s16),
                  Expanded(
                    child: TuishTextField(
                      label: 'ZIP Code',
                      hint: 'ZIP Code',
                      controller: _zipCodeController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.s20),

              // Default address toggle
              SwitchListTile(
                title: Text(
                  'Set as default address',
                  style: AppTypography.bodyLarge,
                ),
                value: _isDefault,
                activeTrackColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _isDefault = val),
              ),

              const SizedBox(height: AppSizes.s32),

              // Save button
              TuishButton.primary(
                label: 'Save Address',
                isLoading: _isLoading,
                onPressed: _saveAddress,
              ),

              const SizedBox(height: AppSizes.s32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    const uuid = Uuid();
    final address = Address(
      id: uuid.v4(),
      label: _selectedLabel,
      customLabel: _selectedLabel == 'Other'
          ? _customLabelController.text.trim()
          : null,
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim().isEmpty
          ? null
          : _addressLine2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      zipCode: _zipCodeController.text.trim(),
      isDefault: _isDefault,
    );

    final notifier = ref.read(addressManagementProvider.notifier);
    final success = await notifier.addAddress(currentUser.uid, address);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ref.invalidate(addressesProvider(currentUser.uid));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save address'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
