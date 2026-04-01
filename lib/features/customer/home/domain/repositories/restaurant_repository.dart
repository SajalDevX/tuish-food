import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/home/domain/entities/category.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';

abstract class RestaurantRepository {
  Future<Either<Failure, List<Restaurant>>> getNearbyRestaurants({
    required double lat,
    required double lng,
    double radiusKm = 10.0,
  });

  Future<Either<Failure, Restaurant>> getRestaurantById(String id);

  Future<Either<Failure, List<Restaurant>>> searchRestaurants(String query);

  Future<Either<Failure, List<FoodCategory>>> getCategories();

  Future<Either<Failure, List<Restaurant>>> getRestaurantsByCategory(
    String category,
  );

  Stream<Restaurant> watchRestaurant(String id);
}
