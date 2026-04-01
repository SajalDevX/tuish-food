import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/features/delivery/dashboard/presentation/providers/delivery_dashboard_provider.dart';

class OnlineToggle extends ConsumerWidget {
  const OnlineToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return GestureDetector(
      onTap: () => ref.read(isOnlineProvider.notifier).toggle(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s16,
          vertical: AppSizes.s12,
        ),
        decoration: BoxDecoration(
          color: isOnline
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.textHint.withValues(alpha: 0.1),
          borderRadius: AppSizes.borderRadiusM,
          border: Border.all(
            color: isOnline ? AppColors.success : AppColors.textHint,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? AppColors.success : AppColors.textHint,
                boxShadow: isOnline
                    ? [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: AppSizes.s12),
            Text(
              isOnline ? 'Online' : 'Offline',
              style: AppTypography.titleMedium.copyWith(
                color: isOnline ? AppColors.success : AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isOnline
                    ? Icons.toggle_on_rounded
                    : Icons.toggle_off_rounded,
                key: ValueKey(isOnline),
                size: 40,
                color: isOnline ? AppColors.success : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
