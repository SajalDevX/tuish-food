import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';
import 'package:tuish_food/features/customer/home/domain/repositories/restaurant_repository.dart';

class GetRestaurantById {
  final RestaurantRepository repository;

  const GetRestaurantById(this.repository);

  Future<Either<Failure, Restaurant>> call(String id) {
    return repository.getRestaurantById(id);
  }
}
