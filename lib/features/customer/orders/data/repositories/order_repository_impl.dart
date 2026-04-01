import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/orders/data/datasources/order_remote_datasource.dart';
import 'package:tuish_food/features/customer/orders/domain/entities/order.dart';
import 'package:tuish_food/features/customer/orders/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remoteDataSource;

  const OrderRepositoryImpl({required OrderRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<CustomerOrder>>> getCustomerOrders(
      String userId) async {
    try {
      final orders = await _remoteDataSource.getCustomerOrders(userId);
      return Right(orders);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, CustomerOrder>> getOrderDetails(
      String orderId) async {
    try {
      final order = await _remoteDataSource.getOrderDetails(orderId);
      return Right(order);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> cancelOrder(
      String orderId, String reason) async {
    try {
      await _remoteDataSource.cancelOrder(orderId, reason);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Stream<CustomerOrder> watchOrder(String orderId) {
    return _remoteDataSource.watchOrder(orderId);
  }
}
