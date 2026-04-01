import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';
import 'package:tuish_food/features/customer/home/domain/repositories/restaurant_repository.dart';

class GetNearbyRestaurants {
  final RestaurantRepository repository;

  const GetNearbyRestaurants(this.repository);

  Future<Either<Failure, List<Restaurant>>> call({
    required double lat,
    required double lng,
    double radiusKm = 10.0,
  }) {
    return repository.getNearbyRestaurants(
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
    );
  }
}
