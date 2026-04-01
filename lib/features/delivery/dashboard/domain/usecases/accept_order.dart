import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/delivery/dashboard/domain/entities/delivery_order.dart';
import 'package:tuish_food/features/delivery/dashboard/domain/repositories/delivery_repository.dart';

class AcceptOrder {
  final DeliveryRepository repository;

  const AcceptOrder(this.repository);

  Future<Either<Failure, DeliveryOrder>> call(String orderId) {
    return repository.acceptOrder(orderId);
  }
}
