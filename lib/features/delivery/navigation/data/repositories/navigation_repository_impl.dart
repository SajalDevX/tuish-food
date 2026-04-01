import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/core/services/location_service.dart';
import 'package:tuish_food/core/utils/location_utils.dart';
import 'package:tuish_food/features/delivery/navigation/domain/repositories/navigation_repository.dart';

class NavigationRepositoryImpl implements NavigationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LocationService _locationService;

  const NavigationRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required LocationService locationService,
  })  : _firestore = firestore,
        _auth = auth,
        _locationService = locationService;

  @override
  Future<Either<Failure, RouteInfo>> getRouteToRestaurant(
    double restaurantLat,
    double restaurantLng,
  ) async {
    try {
      final position = await _locationService.getCurrentLocation();
      return _buildRoute(
        position.latitude,
        position.longitude,
        restaurantLat,
        restaurantLng,
      );
    } on PermissionDeniedException {
      return const Left(PermissionFailure('Location permission denied'));
    } on LocationServiceDisabledException {
      return const Left(
        PermissionFailure('Location services are disabled'),
      );
    } catch (e) {
      return Left(ServerFailure('Failed to get route: $e'));
    }
  }

  @override
  Future<Either<Failure, RouteInfo>> getRouteToCustomer(
    double customerLat,
    double customerLng,
  ) async {
    try {
      final position = await _locationService.getCurrentLocation();
      return _buildRoute(
        position.latitude,
        position.longitude,
        customerLat,
        customerLng,
      );
    } on PermissionDeniedException {
      return const Left(PermissionFailure('Location permission denied'));
    } on LocationServiceDisabledException {
      return const Left(
        PermissionFailure('Location services are disabled'),
      );
    } catch (e) {
      return Left(ServerFailure('Failed to get route: $e'));
    }
  }

  /// Builds a straight-line route between two points.
  ///
  /// In a production app this would call the Google Directions API to obtain
  /// real polyline data. Here we create intermediate points along the direct
  /// path and estimate the ETA using average driving speed.
  Either<Failure, RouteInfo> _buildRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final distanceKm = LocationUtils.calculateDistance(
      startLat,
      startLng,
      endLat,
      endLng,
    );

    // Generate intermediate waypoints for a smoother polyline.
    const steps = 20;
    final points = <LatLng>[];
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      points.add(LatLng(
        startLat + (endLat - startLat) * t,
        startLng + (endLng - startLng) * t,
      ));
    }

    // Estimate time at ~25 km/h average city driving speed.
    final estimatedMinutes = ((distanceKm / 25) * 60).ceil().clamp(1, 999);

    return Right(RouteInfo(
      polylinePoints: points,
      distanceKm: distanceKm,
      estimatedMinutes: estimatedMinutes,
    ));
  }

  @override
  Future<Either<Failure, void>> updateDriverLocation(
    String orderId,
    Position position,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const Left(AuthFailure('User not authenticated'));
      }

      final docRef = _firestore
          .collection(FirebaseConstants.deliveryLocationsCollection)
          .doc(orderId);

      await docRef.set({
        'orderId': orderId,
        'driverId': user.uid,
        'location': GeoPoint(position.latitude, position.longitude),
        'heading': position.heading,
        'speed': position.speed,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update location: $e'));
    }
  }
}
