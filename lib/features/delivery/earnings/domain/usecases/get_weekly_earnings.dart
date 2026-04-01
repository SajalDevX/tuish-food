import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/delivery/earnings/domain/entities/earnings.dart';
import 'package:tuish_food/features/delivery/earnings/domain/repositories/earnings_repository.dart';

class GetWeeklyEarnings {
  final EarningsRepository repository;

  const GetWeeklyEarnings(this.repository);

  Future<Either<Failure, List<Earnings>>> call(String week) {
    return repository.getWeeklyEarnings(week);
  }
}
