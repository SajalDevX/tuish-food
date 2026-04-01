import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/core/widgets/error_widget.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/features/delivery/earnings/presentation/providers/earnings_provider.dart';
import 'package:tuish_food/features/delivery/earnings/presentation/widgets/earnings_chart.dart';
import 'package:tuish_food/features/delivery/earnings/presentation/widgets/earnings_summary_card.dart';
import 'package:tuish_food/features/delivery/earnings/presentation/widgets/payout_history_tile.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayEarnings = ref.watch(todayEarningsProvider);
    final weeklyEarnings = ref.watch(weeklyEarningsProvider);
    final earningsHistory = ref.watch(earningsHistoryProvider);

    return Scaffold(
      appBar: TuishAppBar(
        title: AppStrings.earnings,
        showBackButton: false,
      ),
      body: RefreshIndicator(
        color: AppColors.secondary,
        onRefresh: () async {
          ref.invalidate(todayEarningsProvider);
          ref.invalidate(weeklyEarningsProvider);
          ref.invalidate(earningsHistoryProvider);
        },
        child: ListView(
          padding: AppSizes.screenPadding,
          children: [
            // Today's earnings summary
            todayEarnings.when(
              data: (earnings) {
                final total = earnings.fold<double>(
                  0,
                  (sum, e) => sum + e.totalEarned,
                );
                final count = earnings.length;
                final average = count > 0 ? total / count : 0.0;

                return EarningsSummaryCard(
                  totalEarnings: total,
                  deliveriesCount: count,
                  averagePerDelivery: average,
                  label: AppStrings.todayEarnings,
                );
              },
              loading: () => const SizedBox(
                height: 160,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.secondary,
                  ),
                ),
              ),
              error: (e, _) => TuishErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(todayEarningsProvider),
              ),
            ),
            const SizedBox(height: AppSizes.s24),

            // Weekly chart
            Text('This Week', style: AppTypography.titleMedium),
            const SizedBox(height: AppSizes.s8),
            weeklyEarnings.when(
              data: (earnings) {
                if (earnings.isEmpty) {
                  return Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: Text(
                      'No earnings this week yet',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                return EarningsChart(weeklyEarnings: earnings);
              },
              loading: () => const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.secondary,
                  ),
                ),
              ),
              error: (e, _) => TuishErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(weeklyEarningsProvider),
              ),
            ),
            const SizedBox(height: AppSizes.s24),

            // Earnings history
            Text('Earnings History', style: AppTypography.titleMedium),
            const SizedBox(height: AppSizes.s12),
            earningsHistory.when(
              data: (earnings) {
                if (earnings.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'No earnings history yet.\nComplete deliveries to start earning.',
                    icon: Icons.account_balance_wallet_outlined,
                  );
                }

                return Column(
                  children: [
                    ...earnings.map(
                      (e) => PayoutHistoryTile(earnings: e),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.s32),
                  child: CircularProgressIndicator(
                    color: AppColors.secondary,
                  ),
                ),
              ),
              error: (e, _) => TuishErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(earningsHistoryProvider),
              ),
            ),
            const SizedBox(height: AppSizes.s32),
          ],
        ),
      ),
    );
  }
}
