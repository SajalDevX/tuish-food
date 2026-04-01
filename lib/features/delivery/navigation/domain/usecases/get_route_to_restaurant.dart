import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/delivery/navigation/domain/repositories/navigation_repository.dart';

class GetRouteToRestaurant {
  final NavigationRepository repository;

  const GetRouteToRestaurant(this.repository);

  Future<Either<Failure, RouteInfo>> call(
    double restaurantLat,
    double restaurantLng,
  ) {
    return repository.getRouteToRestaurant(restaurantLat, restaurantLng);
  }
}
