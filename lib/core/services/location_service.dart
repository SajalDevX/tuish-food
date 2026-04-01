import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// GPS location service that wraps [Geolocator].
///
/// Handles permission checks, one-shot position requests, and continuous
/// location streams.
class LocationService {
  const LocationService();

  // ---------------------------------------------------------------------------
  // Permission helpers
  // ---------------------------------------------------------------------------

  /// Returns the current [LocationPermission] status without prompting the
  /// user.
  Future<LocationPermission> checkPermission() async {
    return Geolocator.checkPermission();
  }

  /// Prompts the user for location permission and returns the result.
  ///
  /// If permission has been permanently denied, this opens the device's app
  /// settings so the user can grant it manually.
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint(
        'LocationService: permission permanently denied -- opening settings',
      );
      await Geolocator.openAppSettings();
    }

    return permission;
  }

  /// Whether the device-level location service (GPS / network) is turned on.
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  // ---------------------------------------------------------------------------
  // Position
  // ---------------------------------------------------------------------------

  /// Returns the device's current position.
  ///
  /// Throws a [PermissionDeniedException] or [LocationServiceDisabledException]
  /// if the necessary preconditions are not met.
  Future<Position> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration? timeLimit,
  }) async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const PermissionDeniedException('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException(
        'Location permission permanently denied',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        timeLimit: timeLimit,
      ),
    );
  }

  /// Returns a stream of position updates.
  ///
  /// Useful for delivery-partner tracking where continuous updates are needed.
  Stream<Position> getLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
    Duration? intervalDuration,
  }) {
    final settings = AndroidSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      intervalDuration: intervalDuration ?? const Duration(seconds: 5),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'Tuish Food',
        notificationText: 'Tracking your location for delivery',
        enableWakeLock: true,
      ),
    );

    return Geolocator.getPositionStream(locationSettings: settings);
  }

  /// Calculates the distance (in metres) between two geo-coordinates.
  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}

// -----------------------------------------------------------------------------
// Riverpod provider
// -----------------------------------------------------------------------------

final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});
