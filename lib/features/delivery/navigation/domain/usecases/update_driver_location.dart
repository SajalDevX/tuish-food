import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/delivery/navigation/domain/repositories/navigation_repository.dart';

class UpdateDriverLocation {
  final NavigationRepository repository;

  const UpdateDriverLocation(this.repository);

  Future<Either<Failure, void>> call(String orderId, Position position) {
    return repository.updateDriverLocation(orderId, position);
  }
}
