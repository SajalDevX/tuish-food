import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/admin/restaurant_management/domain/repositories/admin_restaurant_repository.dart';

class DeleteRestaurant {
  final AdminRestaurantRepository repository;

  const DeleteRestaurant(this.repository);

  Future<Either<Failure, void>> call(String restaurantId) {
    return repository.deleteRestaurant(restaurantId);
  }
}
