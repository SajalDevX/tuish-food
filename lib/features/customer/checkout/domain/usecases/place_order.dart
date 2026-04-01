import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/checkout/domain/repositories/checkout_repository.dart';

class PlaceOrder {
  final CheckoutRepository repository;

  const PlaceOrder(this.repository);

  Future<Either<Failure, String>> call(PlaceOrderParams params) {
    return repository.placeOrder(params);
  }
}
