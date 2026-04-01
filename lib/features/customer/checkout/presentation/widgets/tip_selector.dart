import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';

class TipSelector extends StatefulWidget {
  const TipSelector({
    super.key,
    required this.selectedTip,
    required this.onTipChanged,
  });

  final double selectedTip;
  final ValueChanged<double> onTipChanged;

  @override
  State<TipSelector> createState() => _TipSelectorState();
}

class _TipSelectorState extends State<TipSelector> {
  static const _presetTips = [0.0, 20.0, 30.0, 50.0];
  bool _isCustom = false;
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSizes.paddingAllM,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSizes.borderRadiusM,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.volunteer_activism,
                size: 20,
                color: AppColors.secondary,
              ),
              const SizedBox(width: AppSizes.s8),
              Text(
                'Tip your delivery partner',
                style: AppTypography.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s4),
          Text(
            'Your kindness means a lot! 100% of the tip goes to them.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSizes.s12),

          // Preset tips
          Row(
            children: [
              ..._presetTips.map((tip) {
                final isSelected = !_isCustom && widget.selectedTip == tip;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() => _isCustom = false);
                        widget.onTipChanged(tip);
                      },
                      borderRadius: AppSizes.borderRadiusS,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.s8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.secondary.withValues(alpha: 0.1)
                              : AppColors.background,
                          borderRadius: AppSizes.borderRadiusS,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.divider,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tip == 0
                              ? 'No tip'
                              : '\u20B9${tip.toStringAsFixed(0)}',
                          style: AppTypography.labelMedium.copyWith(
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Custom button
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() => _isCustom = true);
                    },
                    borderRadius: AppSizes.borderRadiusS,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.s8,
                      ),
                      decoration: BoxDecoration(
                        color: _isCustom
                            ? AppColors.secondary.withValues(alpha: 0.1)
                            : AppColors.background,
                        borderRadius: AppSizes.borderRadiusS,
                        border: Border.all(
                          color: _isCustom
                              ? AppColors.secondary
                              : AppColors.divider,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Custom',
                        style: AppTypography.labelMedium.copyWith(
                          color: _isCustom
                              ? AppColors.secondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Custom tip input
          if (_isCustom) ...[
            const SizedBox(height: AppSizes.s12),
            Row(
              children: [
                Text('\u20B9', style: AppTypography.titleMedium),
                const SizedBox(width: AppSizes.s8),
                Expanded(
                  child: TextField(
                    controller: _customController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s12,
                        vertical: AppSizes.s8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppSizes.borderRadiusS,
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                    ),
                    onChanged: (value) {
                      final amount = double.tryParse(value) ?? 0;
                      widget.onTipChanged(amount);
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
