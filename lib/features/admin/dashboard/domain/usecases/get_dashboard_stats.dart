import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/admin/dashboard/domain/entities/analytics_data.dart';
import 'package:tuish_food/features/admin/dashboard/domain/repositories/analytics_repository.dart';

class GetDashboardStats {
  final AnalyticsRepository repository;

  const GetDashboardStats(this.repository);

  Future<Either<Failure, AnalyticsData>> call(String period) {
    return repository.getDashboardStats(period);
  }
}
