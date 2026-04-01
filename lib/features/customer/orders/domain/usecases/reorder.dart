import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/orders/domain/entities/order.dart';
import 'package:tuish_food/features/customer/orders/domain/repositories/order_repository.dart';

class Reorder {
  final OrderRepository repository;

  const Reorder(this.repository);

  /// Fetches the order details so the items can be added back to the cart.
  Future<Either<Failure, CustomerOrder>> call(String orderId) {
    return repository.getOrderDetails(orderId);
  }
}
