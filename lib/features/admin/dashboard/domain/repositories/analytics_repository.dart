import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/admin/dashboard/domain/entities/analytics_data.dart';

abstract class AnalyticsRepository {
  Future<Either<Failure, AnalyticsData>> getDashboardStats(String period);

  Future<Either<Failure, List<RevenueDataPoint>>> getRevenueReport(
    DateTime startDate,
    DateTime endDate,
  );

  Future<Either<Failure, Map<String, int>>> getOrderAnalytics();
}
