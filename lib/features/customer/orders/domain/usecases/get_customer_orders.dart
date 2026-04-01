import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/orders/domain/entities/order.dart';
import 'package:tuish_food/features/customer/orders/domain/repositories/order_repository.dart';

class GetCustomerOrders {
  final OrderRepository repository;

  const GetCustomerOrders(this.repository);

  Future<Either<Failure, List<CustomerOrder>>> call(String userId) {
    return repository.getCustomerOrders(userId);
  }
}
