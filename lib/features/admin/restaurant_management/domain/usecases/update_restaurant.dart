import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/admin/restaurant_management/domain/repositories/admin_restaurant_repository.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';

class UpdateRestaurant {
  final AdminRestaurantRepository repository;

  const UpdateRestaurant(this.repository);

  Future<Either<Failure, Restaurant>> call(
    String restaurantId,
    Map<String, dynamic> data,
  ) {
    return repository.updateRestaurant(restaurantId, data);
  }
}
