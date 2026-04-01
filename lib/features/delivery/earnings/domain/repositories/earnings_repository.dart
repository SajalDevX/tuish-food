import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/delivery/earnings/domain/entities/earnings.dart';

abstract class EarningsRepository {
  /// Returns earnings for a specific date.
  Future<Either<Failure, List<Earnings>>> getDailyEarnings(DateTime date);

  /// Returns earnings for a specific week identifier (e.g. "2026-W13").
  Future<Either<Failure, List<Earnings>>> getWeeklyEarnings(String week);

  /// Returns the earnings history with a limit.
  Future<Either<Failure, List<Earnings>>> getEarningsHistory(int limit);
}
