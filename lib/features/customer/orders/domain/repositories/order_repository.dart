import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/orders/domain/entities/order.dart';

abstract class OrderRepository {
  Future<Either<Failure, List<CustomerOrder>>> getCustomerOrders(String userId);
  Future<Either<Failure, CustomerOrder>> getOrderDetails(String orderId);
  Future<Either<Failure, void>> cancelOrder(String orderId, String reason);
  Stream<CustomerOrder> watchOrder(String orderId);
}
