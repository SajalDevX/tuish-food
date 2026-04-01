import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/core/widgets/loading_overlay.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/core/widgets/tuish_text_field.dart';
import 'package:tuish_food/injection_container.dart';

/// Provider that loads vehicle info for the current user from Firestore.
final _vehicleInfoProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final firestore = ref.watch(firestoreProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final doc = await firestore
      .collection(FirebaseConstants.usersCollection)
      .doc(user.uid)
      .get();

  if (!doc.exists) return null;
  final data = doc.data();
  return data?['vehicleInfo'] as Map<String, dynamic>?;
});

class VehicleInfoScreen extends ConsumerStatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  ConsumerState<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends ConsumerState<VehicleInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();
  final _licenseNumberController = TextEditingController();

  String _selectedVehicleType = 'Motorcycle';
  bool _isSaving = false;
  bool _isInitialized = false;

  static const _vehicleTypes = ['Bicycle', 'Motorcycle', 'Car'];

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  void _initializeFromData(Map<String, dynamic>? data) {
    if (_isInitialized || data == null) return;
    _isInitialized = true;

    final vehicleType = data['vehicleType'] as String?;
    if (vehicleType != null && _vehicleTypes.contains(vehicleType)) {
      _selectedVehicleType = vehicleType;
    }
    _vehicleNumberController.text = data['vehicleNumber'] as String? ?? '';
    _licenseNumberController.text = data['licenseNumber'] as String? ?? '';
  }

  Future<void> _saveVehicleInfo() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final firestore = ref.read(firestoreProvider);
      await firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .update({
        'vehicleInfo': {
          'vehicleType': _selectedVehicleType,
          'vehicleNumber': _vehicleNumberController.text.trim(),
          'licenseNumber': _licenseNumberController.text.trim(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle info saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
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
    final vehicleInfoAsync = ref.watch(_vehicleInfoProvider);

    return Scaffold(
      appBar: const TuishAppBar(title: 'Vehicle Info'),
      body: vehicleInfoAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          _initializeFromData(data);
          return LoadingOverlay(
            isLoading: _isSaving,
            child: SingleChildScrollView(
              padding: AppSizes.paddingAllM,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vehicle Type', style: AppTypography.labelLarge),
                    const SizedBox(height: AppSizes.s8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedVehicleType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: AppSizes.borderRadiusM,
                          borderSide:
                              const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppSizes.borderRadiusM,
                          borderSide:
                              const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppSizes.borderRadiusM,
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.s16,
                          vertical: AppSizes.s16,
                        ),
                      ),
                      items: _vehicleTypes
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type,
                                    style: AppTypography.bodyLarge),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedVehicleType = value);
                        }
                      },
                    ),
                    const SizedBox(height: AppSizes.s24),

                    TuishTextField(
                      label: 'Vehicle Number',
                      hint: 'e.g. AB-1234',
                      controller: _vehicleNumberController,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (_selectedVehicleType != 'Bicycle' &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Please enter vehicle number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.s24),

                    TuishTextField(
                      label: 'License Number',
                      hint: 'e.g. DL-1234567890',
                      controller: _licenseNumberController,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (_selectedVehicleType != 'Bicycle' &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Please enter license number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.s32),

                    TuishButton.primary(
                      label: AppStrings.save,
                      onPressed: _isSaving ? null : _saveVehicleInfo,
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
