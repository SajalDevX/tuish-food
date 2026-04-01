import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/loading_overlay.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/core/widgets/tuish_text_field.dart';
import 'package:tuish_food/features/admin/promotions/presentation/providers/promotions_provider.dart';

class CreatePromotionScreen extends ConsumerStatefulWidget {
  const CreatePromotionScreen({super.key});

  @override
  ConsumerState<CreatePromotionScreen> createState() =>
      _CreatePromotionScreenState();
}

class _CreatePromotionScreenState
    extends ConsumerState<CreatePromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  final _minOrderAmountController = TextEditingController();
  final _usageLimitController = TextEditingController();
  final _perUserLimitController = TextEditingController();

  String _discountType = 'percentage';
  DateTime? _validFrom;
  DateTime? _validTo;
  bool _isActive = true;

  final _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _maxDiscountController.dispose();
    _minOrderAmountController.dispose();
    _usageLimitController.dispose();
    _perUserLimitController.dispose();
    super.dispose();
  }

  Future<void> _selectDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_validFrom ?? now)
          : (_validTo ?? now.add(const Duration(days: 30))),
      firstDate: isFrom ? now.subtract(const Duration(days: 365)) : now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _validFrom = picked;
        } else {
          _validTo = picked;
        }
      });
    }
  }

  Future<void> _createPromotion() async {
    if (!_formKey.currentState!.validate()) return;

    if (_validFrom == null || _validTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select valid from and valid to dates'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final data = <String, dynamic>{
      'code': _codeController.text.trim().toUpperCase(),
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'discountType': _discountType,
      'discountValue':
          double.tryParse(_discountValueController.text.trim()) ?? 0,
      'maxDiscount':
          double.tryParse(_maxDiscountController.text.trim()) ?? 0,
      'minOrderAmount':
          double.tryParse(_minOrderAmountController.text.trim()) ?? 0,
      'usageLimit':
          int.tryParse(_usageLimitController.text.trim()) ?? 0,
      'perUserLimit':
          int.tryParse(_perUserLimitController.text.trim()) ?? 0,
      'validFrom': Timestamp.fromDate(_validFrom!),
      'validTo': Timestamp.fromDate(_validTo!),
      'isActive': _isActive,
    };

    final success = await ref
        .read(createPromotionProvider.notifier)
        .createPromotion(data);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promotion created successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createPromotionProvider);
    final isLoading = createState.isLoading;

    return Scaffold(
      appBar: const TuishAppBar(title: 'Create Promotion'),
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SingleChildScrollView(
          padding: AppSizes.paddingAllM,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Promo code
                TuishTextField(
                  label: 'Promo Code',
                  hint: 'e.g. SUMMER25',
                  controller: _codeController,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a promo code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.s16),

                // Title
                TuishTextField(
                  label: 'Title',
                  hint: 'e.g. Summer Sale',
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.s16),

                // Description
                TuishTextField(
                  label: 'Description',
                  hint: 'Describe the promotion...',
                  controller: _descriptionController,
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSizes.s16),

                // Discount type dropdown
                Text('Discount Type', style: AppTypography.labelLarge),
                const SizedBox(height: AppSizes.s8),
                DropdownButtonFormField<String>(
                  initialValue: _discountType,
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s16,
                      vertical: AppSizes.s16,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'percentage',
                      child: Text('Percentage'),
                    ),
                    DropdownMenuItem(
                      value: 'fixed',
                      child: Text('Fixed Amount'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _discountType = value);
                    }
                  },
                ),
                const SizedBox(height: AppSizes.s16),

                // Discount value
                TuishTextField(
                  label: _discountType == 'percentage'
                      ? 'Discount Percentage'
                      : 'Discount Amount',
                  hint: _discountType == 'percentage'
                      ? 'e.g. 25'
                      : 'e.g. 100',
                  controller: _discountValueController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter discount value';
                    }
                    final number = double.tryParse(value.trim());
                    if (number == null || number <= 0) {
                      return 'Please enter a valid number';
                    }
                    if (_discountType == 'percentage' && number > 100) {
                      return 'Percentage cannot exceed 100';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.s16),

                // Max discount (for percentage type)
                if (_discountType == 'percentage') ...[
                  TuishTextField(
                    label: 'Max Discount Amount',
                    hint: 'e.g. 200 (0 for no limit)',
                    controller: _maxDiscountController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSizes.s16),
                ],

                // Min order amount
                TuishTextField(
                  label: 'Minimum Order Amount',
                  hint: 'e.g. 500 (0 for no minimum)',
                  controller: _minOrderAmountController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSizes.s16),

                // Usage limit
                Row(
                  children: [
                    Expanded(
                      child: TuishTextField(
                        label: 'Usage Limit',
                        hint: '0 = unlimited',
                        controller: _usageLimitController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: AppSizes.s16),
                    Expanded(
                      child: TuishTextField(
                        label: 'Per User Limit',
                        hint: '0 = unlimited',
                        controller: _perUserLimitController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.s24),

                // Date pickers
                Text('Validity Period', style: AppTypography.labelLarge),
                const SizedBox(height: AppSizes.s8),
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerField(
                        label: 'Valid From',
                        date: _validFrom,
                        dateFormat: _dateFormat,
                        onTap: () => _selectDate(isFrom: true),
                      ),
                    ),
                    const SizedBox(width: AppSizes.s16),
                    Expanded(
                      child: _DatePickerField(
                        label: 'Valid To',
                        date: _validTo,
                        dateFormat: _dateFormat,
                        onTap: () => _selectDate(isFrom: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.s24),

                // Active toggle
                SwitchListTile(
                  title: Text('Active', style: AppTypography.titleSmall),
                  subtitle: Text(
                    _isActive
                        ? 'Promotion is active and visible'
                        : 'Promotion is inactive',
                    style: AppTypography.bodySmall,
                  ),
                  value: _isActive,
                  activeThumbColor: AppColors.success,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    setState(() => _isActive = value);
                  },
                ),
                const SizedBox(height: AppSizes.s24),

                // Create button
                TuishButton.primary(
                  label: 'Create Promotion',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _createPromotion,
                ),

                const SizedBox(height: AppSizes.s48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.date,
    required this.dateFormat,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSizes.borderRadiusM,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s16,
          vertical: AppSizes.s16,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: AppSizes.borderRadiusM,
          color: AppColors.surface,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.labelSmall),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? dateFormat.format(date!)
                        : 'Select date',
                    style: date != null
                        ? AppTypography.bodyMedium
                        : AppTypography.bodyMedium
                            .copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
