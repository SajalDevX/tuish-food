import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_item.dart';

class CustomizationSelector extends StatelessWidget {
  const CustomizationSelector({
    super.key,
    required this.customization,
    required this.selectedOptionIds,
    required this.onChanged,
  });

  final MenuItemCustomization customization;
  final Set<String> selectedOptionIds;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(customization.title, style: AppTypography.titleSmall),
            if (customization.required) ...[
              const SizedBox(width: AppSizes.s8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: AppSizes.borderRadiusS,
                ),
                child: Text(
                  'Required',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (customization.multiSelect)
          Text(
            'Select up to ${customization.maxSelections}',
            style: AppTypography.bodySmall,
          ),
        const SizedBox(height: AppSizes.s8),
        ...customization.options.map((option) {
          final isSelected = selectedOptionIds.contains(option.id);

          if (customization.multiSelect) {
            return CheckboxListTile(
              title: Text(option.name, style: AppTypography.bodyMedium),
              subtitle: option.additionalPrice > 0
                  ? Text(
                      '+\u20B9${option.additionalPrice.toStringAsFixed(0)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    )
                  : null,
              value: isSelected,
              activeColor: AppColors.primary,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (checked) {
                final newSelection = Set<String>.from(selectedOptionIds);
                if (checked == true) {
                  if (newSelection.length < customization.maxSelections) {
                    newSelection.add(option.id);
                  }
                } else {
                  newSelection.remove(option.id);
                }
                onChanged(newSelection);
              },
            );
          } else {
            final isSelected = selectedOptionIds.contains(option.id);
            return ListTile(
              title: Text(option.name, style: AppTypography.bodyMedium),
              subtitle: option.additionalPrice > 0
                  ? Text(
                      '+\u20B9${option.additionalPrice.toStringAsFixed(0)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    )
                  : null,
              // ignore: deprecated_member_use
              leading: Radio<bool>(
                value: true,
                // ignore: deprecated_member_use
                groupValue: isSelected,
                activeColor: AppColors.primary,
                // ignore: deprecated_member_use
                onChanged: (_) => onChanged({option.id}),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
              onTap: () => onChanged({option.id}),
            );
          }
        }),
      ],
    );
  }
}
