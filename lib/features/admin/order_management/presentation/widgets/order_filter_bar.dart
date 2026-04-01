import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/features/admin/order_management/presentation/providers/order_management_provider.dart';

class OrderFilterBar extends ConsumerWidget {
  const OrderFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(orderFilterProvider);

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
        children: [
          // "All" chip
          _FilterChipWidget(
            label: 'All',
            isSelected: filter.status == null,
            onSelected: () {
              ref.read(orderFilterProvider.notifier).update(
                  filter.copyWith(clearStatus: true));
            },
          ),

          // Status chips
          ...OrderStatus.values.map((status) {
            return _FilterChipWidget(
              label: status.displayName,
              isSelected: filter.status == status,
              onSelected: () {
                ref.read(orderFilterProvider.notifier).update(
                    filter.copyWith(status: status));
              },
            );
          }),

          // Date range button
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.s8),
            child: ActionChip(
              avatar: Icon(
                Icons.date_range,
                size: 16,
                color: filter.startDate != null
                    ? AppColors.onPrimary
                    : AppColors.textSecondary,
              ),
              label: Text(
                filter.startDate != null ? 'Date Set' : 'Date Range',
                style: AppTypography.labelMedium.copyWith(
                  color: filter.startDate != null
                      ? AppColors.onPrimary
                      : AppColors.textPrimary,
                ),
              ),
              backgroundColor: filter.startDate != null
                  ? AppColors.primary
                  : AppColors.surface,
              side: BorderSide(
                color: filter.startDate != null
                    ? AppColors.primary
                    : AppColors.divider,
              ),
              onPressed: () => _showDateRangePicker(context, ref, filter),
            ),
          ),

          // Clear filters
          if (filter.status != null || filter.startDate != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSizes.s8),
              child: ActionChip(
                avatar: const Icon(Icons.clear, size: 16,
                    color: AppColors.error),
                label: Text(
                  'Clear',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.error),
                ),
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.error),
                onPressed: () {
                  ref.read(orderFilterProvider.notifier).update(
                      const OrderFilter());
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker(
    BuildContext context,
    WidgetRef ref,
    OrderFilter currentFilter,
  ) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: currentFilter.startDate != null &&
              currentFilter.endDate != null
          ? DateTimeRange(
              start: currentFilter.startDate!,
              end: currentFilter.endDate!,
            )
          : null,
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
      ref.read(orderFilterProvider.notifier).update(currentFilter.copyWith(
        startDate: picked.start,
        endDate: picked.end,
      ));
    }
  }
}

class _FilterChipWidget extends StatelessWidget {
  const _FilterChipWidget({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.s8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
        ),
        selectedColor: AppColors.primary,
        checkmarkColor: AppColors.onPrimary,
        backgroundColor: AppColors.surface,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.divider,
        ),
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
