import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/delivery/dashboard/data/datasources/delivery_remote_datasource.dart';
import 'package:tuish_food/features/delivery/dashboard/domain/entities/delivery_order.dart';
import 'package:tuish_food/features/delivery/dashboard/domain/repositories/delivery_repository.dart';

class DeliveryRepositoryImpl implements DeliveryRepository {
  final DeliveryRemoteDatasource _remoteDatasource;

  const DeliveryRepositoryImpl({
    required DeliveryRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  @override
  Stream<Either<Failure, List<DeliveryOrder>>> getAvailableOrders() {
    return _remoteDatasource.getAvailableOrders().map(
          (orders) => Right<Failure, List<DeliveryOrder>>(orders),
        );
  }

  @override
  Future<Either<Failure, DeliveryOrder>> acceptOrder(String orderId) async {
    try {
      final order = await _remoteDatasource.acceptOrder(orderId);
      return Right(order);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectOrder(String orderId) async {
    try {
      await _remoteDatasource.rejectOrder(orderId);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    try {
      await _remoteDatasource.updateOrderStatus(orderId, status);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DeliveryOrder?>> getActiveDelivery() async {
    try {
      final order = await _remoteDatasource.getActiveDelivery();
      return Right(order);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DeliveryOrder>>> getDeliveryHistory() async {
    try {
      final orders = await _remoteDatasource.getDeliveryHistory();
      return Right(orders);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
