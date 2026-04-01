import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/admin/restaurant_management/domain/repositories/admin_restaurant_repository.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';

class CreateRestaurant {
  final AdminRestaurantRepository repository;

  const CreateRestaurant(this.repository);

  Future<Either<Failure, Restaurant>> call(Map<String, dynamic> data) {
    return repository.createRestaurant(data);
  }
}
