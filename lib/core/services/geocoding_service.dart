import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

class PlacemarkResult {
  final String displayName;
  final String city;
  final String state;
  final String zipCode;

  const PlacemarkResult({
    required this.displayName,
    required this.city,
    required this.state,
    required this.zipCode,
  });
}

class GeocodingService {
  const GeocodingService();

  /// Converts [lat]/[lng] to a human-readable [PlacemarkResult].
  /// Returns null if geocoding fails or returns no results.
  Future<PlacemarkResult?> reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;

      final parts = [p.subLocality, p.locality]
          .where((s) => s != null && s.isNotEmpty)
          .join(', ');

      return PlacemarkResult(
        displayName: parts.isNotEmpty ? parts : (p.name ?? ''),
        city: p.locality ?? '',
        state: p.administrativeArea ?? '',
        zipCode: p.postalCode ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return const GeocodingService();
});
