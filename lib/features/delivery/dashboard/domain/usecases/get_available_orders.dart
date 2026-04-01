import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/delivery/dashboard/domain/entities/delivery_order.dart';
import 'package:tuish_food/features/delivery/dashboard/domain/repositories/delivery_repository.dart';

class GetAvailableOrders {
  final DeliveryRepository repository;

  const GetAvailableOrders(this.repository);

  Stream<Either<Failure, List<DeliveryOrder>>> call() {
    return repository.getAvailableOrders();
  }
}
