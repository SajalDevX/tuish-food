import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_item.dart';

abstract class AdminRestaurantRepository {
  Future<Either<Failure, List<Restaurant>>> getAllRestaurants();

  Future<Either<Failure, Restaurant>> createRestaurant(
    Map<String, dynamic> data,
  );

  Future<Either<Failure, Restaurant>> updateRestaurant(
    String restaurantId,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, void>> deleteRestaurant(String restaurantId);

  Future<Either<Failure, void>> toggleRestaurantStatus(
    String restaurantId,
    bool isActive,
  );

  Future<Either<Failure, List<MenuItem>>> getMenuItems(String restaurantId);

  Future<Either<Failure, MenuItem>> addMenuItem(
    String restaurantId,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, MenuItem>> updateMenuItem(
    String restaurantId,
    String menuItemId,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, void>> deleteMenuItem(
    String restaurantId,
    String menuItemId,
  );
}
