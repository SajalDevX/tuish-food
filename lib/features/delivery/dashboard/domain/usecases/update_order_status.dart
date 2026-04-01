import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/delivery/dashboard/domain/repositories/delivery_repository.dart';

class UpdateOrderStatus {
  final DeliveryRepository repository;

  const UpdateOrderStatus(this.repository);

  Future<Either<Failure, void>> call(String orderId, OrderStatus status) {
    return repository.updateOrderStatus(orderId, status);
  }
}
