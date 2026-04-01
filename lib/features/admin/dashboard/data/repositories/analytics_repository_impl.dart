import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/admin/dashboard/data/datasources/analytics_remote_datasource.dart';
import 'package:tuish_food/features/admin/dashboard/domain/entities/analytics_data.dart';
import 'package:tuish_food/features/admin/dashboard/domain/repositories/analytics_repository.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsRemoteDatasource _datasource;

  const AnalyticsRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, AnalyticsData>> getDashboardStats(
      String period) async {
    try {
      final result = await _datasource.getDashboardStats(period);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RevenueDataPoint>>> getRevenueReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final result = await _datasource.getRevenueReport(startDate, endDate);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getOrderAnalytics() async {
    try {
      final result = await _datasource.getOrderAnalytics();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
