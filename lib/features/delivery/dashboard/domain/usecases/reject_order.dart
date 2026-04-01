import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/delivery/dashboard/domain/repositories/delivery_repository.dart';

class RejectOrder {
  final DeliveryRepository repository;

  const RejectOrder(this.repository);

  Future<Either<Failure, void>> call(String orderId) {
    return repository.rejectOrder(orderId);
  }
}
