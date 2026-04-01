import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';
import 'package:tuish_food/features/customer/home/domain/repositories/restaurant_repository.dart';

class SearchRestaurants {
  final RestaurantRepository repository;

  const SearchRestaurants(this.repository);

  Future<Either<Failure, List<Restaurant>>> call(String query) {
    return repository.searchRestaurants(query);
  }
}
