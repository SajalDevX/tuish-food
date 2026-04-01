import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/delivery/earnings/data/datasources/earnings_remote_datasource.dart';
import 'package:tuish_food/features/delivery/earnings/domain/entities/earnings.dart';
import 'package:tuish_food/features/delivery/earnings/domain/repositories/earnings_repository.dart';

class EarningsRepositoryImpl implements EarningsRepository {
  final EarningsRemoteDatasource _remoteDatasource;

  const EarningsRepositoryImpl({
    required EarningsRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, List<Earnings>>> getDailyEarnings(
    DateTime date,
  ) async {
    try {
      final earnings = await _remoteDatasource.getDailyEarnings(date);
      return Right(earnings);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Earnings>>> getWeeklyEarnings(
    String week,
  ) async {
    try {
      final earnings = await _remoteDatasource.getWeeklyEarnings(week);
      return Right(earnings);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Earnings>>> getEarningsHistory(
    int limit,
  ) async {
    try {
      final earnings = await _remoteDatasource.getEarningsHistory(limit);
      return Right(earnings);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
