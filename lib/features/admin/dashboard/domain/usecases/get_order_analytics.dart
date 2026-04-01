import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/admin/dashboard/domain/repositories/analytics_repository.dart';

class GetOrderAnalytics {
  final AnalyticsRepository repository;

  const GetOrderAnalytics(this.repository);

  Future<Either<Failure, Map<String, int>>> call() {
    return repository.getOrderAnalytics();
  }
}
