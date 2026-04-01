import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/orders/domain/entities/order.dart';
import 'package:tuish_food/features/customer/orders/domain/repositories/order_repository.dart';

class GetOrderDetails {
  final OrderRepository repository;

  const GetOrderDetails(this.repository);

  Future<Either<Failure, CustomerOrder>> call(String orderId) {
    return repository.getOrderDetails(orderId);
  }
}
