import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/admin/restaurant_management/domain/repositories/admin_restaurant_repository.dart';

class ToggleRestaurantStatus {
  final AdminRestaurantRepository repository;

  const ToggleRestaurantStatus(this.repository);

  Future<Either<Failure, void>> call(String restaurantId, bool isActive) {
    return repository.toggleRestaurantStatus(restaurantId, isActive);
  }
}
