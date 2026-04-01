import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tuish_food/core/errors/failures.dart';

/// Route data returned by the navigation repository.
class RouteInfo {
  final List<LatLng> polylinePoints;
  final double distanceKm;
  final int estimatedMinutes;

  const RouteInfo({
    required this.polylinePoints,
    required this.distanceKm,
    required this.estimatedMinutes,
  });
}

abstract class NavigationRepository {
  /// Gets a route from the driver's current location to the restaurant.
  Future<Either<Failure, RouteInfo>> getRouteToRestaurant(
    double restaurantLat,
    double restaurantLng,
  );

  /// Gets a route from the restaurant to the customer's location.
  Future<Either<Failure, RouteInfo>> getRouteToCustomer(
    double customerLat,
    double customerLng,
  );

  /// Updates the driver's real-time location in Firestore.
  Future<Either<Failure, void>> updateDriverLocation(
    String orderId,
    Position position,
  );
}
