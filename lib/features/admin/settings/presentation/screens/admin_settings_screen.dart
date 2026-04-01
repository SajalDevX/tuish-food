import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/loading_overlay.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/core/widgets/tuish_text_field.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;

  // Controllers
  final _serviceFeeController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _taxController = TextEditingController();
  final _maxRadiusController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _supportEmailController = TextEditingController();
  final _supportPhoneController = TextEditingController();
  final _forceUpdateVersionController = TextEditingController();
  bool _maintenanceMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _serviceFeeController.dispose();
    _deliveryFeeController.dispose();
    _taxController.dispose();
    _maxRadiusController.dispose();
    _minOrderController.dispose();
    _supportEmailController.dispose();
    _supportPhoneController.dispose();
    _forceUpdateVersionController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('settings')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _serviceFeeController.text =
            (data['serviceFeePercent'] ?? 5.0).toString();
        _deliveryFeeController.text =
            (data['deliveryFee'] ?? 40.0).toString();
        _taxController.text = (data['taxPercent'] ?? 5.0).toString();
        _maxRadiusController.text =
            (data['maxDeliveryRadiusKm'] ?? 15.0).toString();
        _minOrderController.text =
            (data['minOrderAmount'] ?? 100.0).toString();
        _supportEmailController.text =
            data['supportEmail'] ?? 'support@tuishfood.com';
        _supportPhoneController.text =
            data['supportPhone'] ?? '+91-1234567890';
        _forceUpdateVersionController.text =
            data['forceUpdateVersion'] ?? '1.0.0';
        _maintenanceMode = data['maintenanceMode'] ?? false;
      } else {
        // Set defaults
        _serviceFeeController.text = '5.0';
        _deliveryFeeController.text = '40.0';
        _taxController.text = '5.0';
        _maxRadiusController.text = '15.0';
        _minOrderController.text = '100.0';
        _supportEmailController.text = 'support@tuishfood.com';
        _supportPhoneController.text = '+91-1234567890';
        _forceUpdateVersionController.text = '1.0.0';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('app_config')
          .doc('settings')
          .set({
        'serviceFeePercent': double.parse(_serviceFeeController.text),
        'deliveryFee': double.parse(_deliveryFeeController.text),
        'taxPercent': double.parse(_taxController.text),
        'maxDeliveryRadiusKm': double.parse(_maxRadiusController.text),
        'minOrderAmount': double.parse(_minOrderController.text),
        'supportEmail': _supportEmailController.text.trim(),
        'supportPhone': _supportPhoneController.text.trim(),
        'maintenanceMode': _maintenanceMode,
        'forceUpdateVersion': _forceUpdateVersionController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TuishAppBar(title: 'App Settings'),
      body: LoadingOverlay(
        isLoading: _isLoading || _isSaving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSizes.paddingAllL,
            children: [
              // --- Fees Section ---
              Text('Fees & Pricing', style: AppTypography.titleMedium),
              const SizedBox(height: AppSizes.s12),

              TuishTextField(
                controller: _serviceFeeController,
                label: 'Service Fee (%)',
                keyboardType: TextInputType.number,
                validator: _validateNumber,
              ),
              const SizedBox(height: AppSizes.s12),

              TuishTextField(
                controller: _deliveryFeeController,
                label: 'Delivery Fee (₹)',
                keyboardType: TextInputType.number,
                validator: _validateNumber,
              ),
              const SizedBox(height: AppSizes.s12),

              TuishTextField(
                controller: _taxController,
                label: 'Tax (%)',
                keyboardType: TextInputType.number,
                validator: _validateNumber,
              ),
              const SizedBox(height: AppSizes.s24),

              // --- Delivery Section ---
              Text('Delivery', style: AppTypography.titleMedium),
              const SizedBox(height: AppSizes.s12),

              TuishTextField(
                controller: _maxRadiusController,
                label: 'Max Delivery Radius (km)',
                keyboardType: TextInputType.number,
                validator: _validateNumber,
              ),
              const SizedBox(height: AppSizes.s12),

              TuishTextField(
                controller: _minOrderController,
                label: 'Minimum Order Amount (₹)',
                keyboardType: TextInputType.number,
                validator: _validateNumber,
              ),
              const SizedBox(height: AppSizes.s24),

              // --- Support Section ---
              Text('Support', style: AppTypography.titleMedium),
              const SizedBox(height: AppSizes.s12),

              TuishTextField(
                controller: _supportEmailController,
                label: 'Support Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSizes.s12),

              TuishTextField(
                controller: _supportPhoneController,
                label: 'Support Phone',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSizes.s24),

              // --- App Controls Section ---
              Text('App Controls', style: AppTypography.titleMedium),
              const SizedBox(height: AppSizes.s12),

              SwitchListTile(
                title: Text('Maintenance Mode',
                    style: AppTypography.bodyLarge),
                subtitle: Text(
                  'When enabled, users see a maintenance message',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                value: _maintenanceMode,
                activeTrackColor: AppColors.primary,
                onChanged: (val) => setState(() => _maintenanceMode = val),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSizes.s12),

              TuishTextField(
                controller: _forceUpdateVersionController,
                label: 'Force Update Version',
                hint: 'e.g. 1.2.0',
              ),
              const SizedBox(height: AppSizes.s32),

              // --- Save Button ---
              TuishButton.primary(
                label: 'Save Settings',
                onPressed: _isSaving ? null : _saveSettings,
                isLoading: _isSaving,
              ),
              const SizedBox(height: AppSizes.s24),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }
}
