import 'dart:math' as math;

/// Pure utility functions for geo-coordinate calculations and address
/// formatting.
abstract final class LocationUtils {
  /// Mean radius of the Earth in kilometres (WGS-84).
  static const double _earthRadiusKm = 6371.0;

  // ---------------------------------------------------------------------------
  // Haversine distance
  // ---------------------------------------------------------------------------

  /// Calculates the great-circle distance between two points on a sphere
  /// using the **Haversine formula**.
  ///
  /// Parameters are in **decimal degrees**.  Returns the distance in
  /// **kilometres**.
  ///
  /// ```dart
  /// final km = LocationUtils.calculateDistance(
  ///   12.9716, 77.5946, // Bangalore
  ///   13.0827, 80.2707, // Chennai
  /// );
  /// ```
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return _earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  // ---------------------------------------------------------------------------
  // Address formatting
  // ---------------------------------------------------------------------------

  /// Builds a single-line address string from a map of address components.
  ///
  /// Recognised keys (all optional):
  /// - `street`, `subLocality`, `locality`, `city`,
  ///   `state`, `postalCode`, `country`
  ///
  /// Components that are `null` or empty are silently skipped.
  ///
  /// ```dart
  /// final address = LocationUtils.formatAddress({
  ///   'street': '123 MG Road',
  ///   'city': 'Bangalore',
  ///   'state': 'Karnataka',
  ///   'postalCode': '560001',
  /// });
  /// // '123 MG Road, Bangalore, Karnataka 560001'
  /// ```
  static String formatAddress(Map<String, dynamic> address) {
    final parts = <String>[];

    void add(String? value) {
      if (value != null && value.trim().isNotEmpty) {
        parts.add(value.trim());
      }
    }

    add(address['street'] as String?);
    add(address['subLocality'] as String?);
    add(address['locality'] as String?);
    add(address['city'] as String?);

    // Combine state and postal code on the same segment when both present.
    final state = (address['state'] as String?)?.trim();
    final postalCode = (address['postalCode'] as String?)?.trim();
    if (state != null && state.isNotEmpty) {
      if (postalCode != null && postalCode.isNotEmpty) {
        parts.add('$state $postalCode');
      } else {
        parts.add(state);
      }
    } else if (postalCode != null && postalCode.isNotEmpty) {
      parts.add(postalCode);
    }

    add(address['country'] as String?);

    return parts.join(', ');
  }

  // ---------------------------------------------------------------------------
  // Bearing
  // ---------------------------------------------------------------------------

  /// Calculates the initial bearing (forward azimuth) in **degrees** from
  /// point 1 to point 2.  The result is in the range [0, 360).
  static double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLon = _degreesToRadians(lon2 - lon1);
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);

    final y = math.sin(dLon) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);

    final bearing = math.atan2(y, x);
    return (bearing * 180.0 / math.pi + 360.0) % 360.0;
  }
}
