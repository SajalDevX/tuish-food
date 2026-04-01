import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/features/delivery/earnings/domain/entities/earnings.dart';

/// Bar chart showing weekly earnings grouped by day of the week.
class EarningsChart extends StatelessWidget {
  const EarningsChart({
    super.key,
    required this.weeklyEarnings,
  });

  final List<Earnings> weeklyEarnings;

  /// Groups earnings by weekday (1=Mon, 7=Sun) and sums totals.
  Map<int, double> get _dailyTotals {
    final totals = <int, double>{};
    for (int i = 1; i <= 7; i++) {
      totals[i] = 0;
    }
    for (final e in weeklyEarnings) {
      final weekday = e.date.weekday;
      totals[weekday] = (totals[weekday] ?? 0) + e.totalEarned;
    }
    return totals;
  }

  String _dayLabel(int weekday) {
    return switch (weekday) {
      1 => 'Mon',
      2 => 'Tue',
      3 => 'Wed',
      4 => 'Thu',
      5 => 'Fri',
      6 => 'Sat',
      7 => 'Sun',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final dailyTotals = _dailyTotals;
    final maxY = dailyTotals.values.fold<double>(
          0,
          (prev, val) => val > prev ? val : prev,
        ) *
        1.2;

    return Container(
      height: 200,
      padding: const EdgeInsets.only(
        top: AppSizes.s16,
        right: AppSizes.s16,
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY < 100 ? 100 : maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '\u20B9${rod.toY.toStringAsFixed(0)}',
                  AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSizes.s4),
                    child: Text(
                      _dayLabel(value.toInt() + 1),
                      style: AppTypography.labelSmall,
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\u20B9${value.toInt()}',
                    style: AppTypography.labelSmall,
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY < 100 ? 25 : maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
            ),
          ),
          barGroups: List.generate(7, (index) {
            final weekday = index + 1;
            final total = dailyTotals[weekday] ?? 0;
            final isToday = DateTime.now().weekday == weekday;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: total,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  color: isToday ? AppColors.secondary : AppColors.secondaryLight,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
