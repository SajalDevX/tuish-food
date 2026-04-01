import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/checkout/data/datasources/payment_remote_datasource.dart';
import 'package:tuish_food/features/customer/checkout/domain/entities/payment.dart';
import 'package:tuish_food/features/customer/checkout/domain/repositories/checkout_repository.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  final PaymentRemoteDatasource remoteDatasource;

  const CheckoutRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, String>> placeOrder(PlaceOrderParams params) async {
    try {
      final orderId = await remoteDatasource.placeOrder(params);
      return Right(orderId);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CouponResult>> applyCoupon({
    required String code,
    required double subtotal,
  }) async {
    try {
      final result = await remoteDatasource.applyCoupon(
        code: code,
        subtotal: subtotal,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Payment>> processPayment({
    required String orderId,
    required PaymentMethod method,
    required double amount,
  }) async {
    try {
      final result = await remoteDatasource.processPayment(
        orderId: orderId,
        method: method,
        amount: amount,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
