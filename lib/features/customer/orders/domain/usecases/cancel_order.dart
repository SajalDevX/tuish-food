import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/orders/domain/repositories/order_repository.dart';

class CancelOrder {
  final OrderRepository repository;

  const CancelOrder(this.repository);

  Future<Either<Failure, void>> call(String orderId, String reason) {
    return repository.cancelOrder(orderId, reason);
  }
}
