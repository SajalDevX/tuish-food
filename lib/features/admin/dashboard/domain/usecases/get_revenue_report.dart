import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/admin/dashboard/domain/entities/analytics_data.dart';
import 'package:tuish_food/features/admin/dashboard/domain/repositories/analytics_repository.dart';

class GetRevenueReport {
  final AnalyticsRepository repository;

  const GetRevenueReport(this.repository);

  Future<Either<Failure, List<RevenueDataPoint>>> call(
    DateTime startDate,
    DateTime endDate,
  ) {
    return repository.getRevenueReport(startDate, endDate);
  }
}
