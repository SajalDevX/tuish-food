# Real-Time Tracking

This document describes the real-time delivery tracking system in Tuish Food, including GPS location streaming, Google Maps rendering, ETA calculation, background location handling, and the delivery partner assignment algorithm.

---

## Architecture Overview

```
+-------------------+     +-------------------+     +-------------------+
| Delivery Partner  |     |     Firestore     |     |     Customer      |
|   (Geolocator)    |     | delivery_locations|     |   (Google Maps)   |
+-------------------+     +-------------------+     +-------------------+
        |                         |                         ^
        |  Write location         |  Stream snapshot        |
        |  every 5 seconds        |  (real-time listener)   |
        +--------->               +------------------------->
                                  |
                                  |  Also read by:
                                  |  - Assignment algorithm
                                  |  - Admin dashboard
                                  |  - ETA calculation
```

### Data Flow

1. **Delivery partner app** uses `Geolocator` to obtain GPS coordinates.
2. **Location updates** are written to the `delivery_locations/{partnerId}` Firestore document.
3. **Customer app** listens to the delivery partner's location document via a `StreamProvider`.
4. **Google Maps widget** renders the partner's position with a custom marker, updated in real-time.
5. **ETA** is calculated using the Google Directions API and refreshed periodically.

---

## Location Update Frequency

| State | Update Interval | Justification |
| ----- | --------------- | ------------- |
| Active delivery (foreground) | Every 5 seconds | Smooth real-time tracking for customer |
| Active delivery (background) | Every 10 seconds | Balance between accuracy and battery |
| Online, no active delivery | Every 15 seconds | Needed for assignment proximity queries |
| Offline | No updates | Location tracking fully stopped |

### Implementation

```dart
class LocationService {
  StreamSubscription<Position>? _locationSubscription;
  Timer? _writeTimer;
  Position? _lastPosition;

  final FirebaseFirestore _firestore;
  final String _partnerId;

  LocationService(this._firestore, this._partnerId);

  Future<void> startTracking({required bool isActiveDelivery}) async {
    final settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: isActiveDelivery ? 10 : 50, // meters
    );

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((position) {
      _lastPosition = position;
    });

    // Write to Firestore at fixed interval
    final interval = isActiveDelivery
        ? const Duration(seconds: 5)
        : const Duration(seconds: 15);

    _writeTimer = Timer.periodic(interval, (_) {
      if (_lastPosition != null) {
        _writeLocation(_lastPosition!);
      }
    });
  }

  Future<void> _writeLocation(Position position) async {
    final geohash = GeoHasher().encode(
      position.longitude,
      position.latitude,
      precision: 6,
    );

    await _firestore.doc('delivery_locations/$_partnerId').set({
      'location': GeoPoint(position.latitude, position.longitude),
      'geohash': geohash,
      'heading': position.heading,
      'speed': position.speed,
      'accuracy': position.accuracy,
      'isOnline': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void stopTracking() {
    _locationSubscription?.cancel();
    _writeTimer?.cancel();
    _locationSubscription = null;
    _writeTimer = null;
  }
}
```

---

## Geohash Strategy

Geohashes encode a geographic location into a short string, enabling efficient range queries in Firestore (which does not natively support geo-queries).

### How It Works

```
Latitude:  40.7128
Longitude: -74.0060
  |
  v
Geohash (precision 6): "dr5rug"
```

A geohash of precision 6 covers approximately a 1.2 km x 0.6 km area.

### Proximity Query

To find delivery partners near a restaurant, we compute the geohash of the restaurant and query for all geohashes in the surrounding cells:

```dart
Future<List<DeliveryLocationEntity>> findNearbyPartners({
  required GeoPoint restaurantLocation,
  required double radiusKm,
}) async {
  final center = GeoHasher().encode(
    restaurantLocation.longitude,
    restaurantLocation.latitude,
    precision: 6,
  );

  // Get neighboring geohash cells (9 cells total: center + 8 neighbors)
  final neighbors = GeoHasher().neighbors(center);
  final searchHashes = [center, ...neighbors.values];

  final results = <DeliveryLocationEntity>[];

  // Query each geohash range
  for (final hash in searchHashes) {
    final snapshot = await _firestore
        .collection('delivery_locations')
        .where('isOnline', isEqualTo: true)
        .where('currentOrderId', isNull: true) // Only free partners
        .where('geohash', isGreaterThanOrEqualTo: hash)
        .where('geohash', isLessThan: '${hash}~')
        .get();

    results.addAll(
      snapshot.docs.map((doc) => DeliveryLocationModel.fromFirestore(doc)),
    );
  }

  // Filter by exact Haversine distance
  return results
      .where((loc) => _haversineDistance(
            restaurantLocation,
            GeoPoint(loc.location.latitude, loc.location.longitude),
          ) <= radiusKm)
      .toList();
}
```

### Why a Separate Collection?

The `delivery_locations` collection is separate from `users` because:

1. **Hot-path writes**: Location updates every 5-15 seconds would cause excessive reads for anyone listening to the `users` collection.
2. **Smaller documents**: Only location-relevant fields, faster reads.
3. **Independent security rules**: Location data has different access patterns.
4. **Query efficiency**: Geohash indexes are not mixed with user profile indexes.

---

## Google Maps Implementation

### Customer Tracking Map

```dart
class DeliveryTrackingMap extends ConsumerStatefulWidget {
  final String orderId;
  final String deliveryPartnerId;
  final GeoPoint customerLocation;

  const DeliveryTrackingMap({
    required this.orderId,
    required this.deliveryPartnerId,
    required this.customerLocation,
    super.key,
  });

  @override
  ConsumerState<DeliveryTrackingMap> createState() => _DeliveryTrackingMapState();
}

class _DeliveryTrackingMapState extends ConsumerState<DeliveryTrackingMap> {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _partnerIcon;
  BitmapDescriptor? _destinationIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
  }

  Future<void> _loadCustomMarkers() async {
    _partnerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/markers/delivery_partner.png',
    );
    _destinationIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/markers/destination.png',
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(
      deliveryPartnerLocationProvider(widget.deliveryPartnerId),
    );

    return locationAsync.when(
      data: (location) {
        final partnerLatLng = LatLng(
          location.location.latitude,
          location.location.longitude,
        );
        final customerLatLng = LatLng(
          widget.customerLocation.latitude,
          widget.customerLocation.longitude,
        );

        // Update polyline route periodically
        _updateRoute(partnerLatLng, customerLatLng);

        // Auto-fit camera to show both markers
        _fitBounds(partnerLatLng, customerLatLng);

        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: partnerLatLng,
            zoom: 14,
          ),
          onMapCreated: (controller) => _mapController = controller,
          markers: {
            Marker(
              markerId: const MarkerId('partner'),
              position: partnerLatLng,
              icon: _partnerIcon ?? BitmapDescriptor.defaultMarker,
              rotation: location.heading ?? 0,
              anchor: const Offset(0.5, 0.5),
            ),
            Marker(
              markerId: const MarkerId('destination'),
              position: customerLatLng,
              icon: _destinationIcon ?? BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          },
          polylines: _polylines,
          myLocationEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Tracking unavailable')),
    );
  }

  void _fitBounds(LatLng partner, LatLng customer) {
    if (_mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        min(partner.latitude, customer.latitude),
        min(partner.longitude, customer.longitude),
      ),
      northeast: LatLng(
        max(partner.latitude, customer.latitude),
        max(partner.longitude, customer.longitude),
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80), // 80px padding
    );
  }
}
```

### Animated Marker Movement

To smooth out the marker transition between location updates (avoiding jumps):

```dart
class AnimatedMarkerController {
  LatLng _currentPosition;
  LatLng _targetPosition;
  Timer? _animationTimer;

  AnimatedMarkerController(this._currentPosition)
      : _targetPosition = _currentPosition;

  void updateTarget(LatLng newTarget) {
    _currentPosition = _targetPosition;
    _targetPosition = newTarget;
    _startAnimation();
  }

  void _startAnimation() {
    _animationTimer?.cancel();
    int step = 0;
    const totalSteps = 50; // 50 steps over ~1 second
    const duration = Duration(milliseconds: 20);

    _animationTimer = Timer.periodic(duration, (timer) {
      step++;
      final t = step / totalSteps;

      final lat = _currentPosition.latitude +
          (_targetPosition.latitude - _currentPosition.latitude) * t;
      final lng = _currentPosition.longitude +
          (_targetPosition.longitude - _currentPosition.longitude) * t;

      onPositionChanged?.call(LatLng(lat, lng));

      if (step >= totalSteps) {
        timer.cancel();
      }
    });
  }

  Function(LatLng)? onPositionChanged;

  void dispose() {
    _animationTimer?.cancel();
  }
}
```

---

## ETA Calculation

### Google Directions API

ETA is calculated by calling the Google Directions API from the client:

```dart
class DirectionsService {
  final String _apiKey;

  DirectionsService(this._apiKey);

  Future<DirectionsResult> getRoute({
    required LatLng origin,
    required LatLng destination,
    TravelMode mode = TravelMode.driving,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=${mode.name}'
      '&key=$_apiKey',
    );

    final response = await http.get(url);
    final json = jsonDecode(response.body);

    if (json['status'] != 'OK') {
      throw DirectionsException(json['status']);
    }

    final route = json['routes'][0];
    final leg = route['legs'][0];

    return DirectionsResult(
      distanceMeters: leg['distance']['value'],
      durationSeconds: leg['duration']['value'],
      durationInTraffic: leg['duration_in_traffic']?['value'],
      polylinePoints: _decodePolyline(route['overview_polyline']['points']),
      steps: (leg['steps'] as List).map((s) => DirectionStep(
        instruction: s['html_instructions'],
        distanceMeters: s['distance']['value'],
        durationSeconds: s['duration']['value'],
        startLocation: LatLng(
          s['start_location']['lat'],
          s['start_location']['lng'],
        ),
        endLocation: LatLng(
          s['end_location']['lat'],
          s['end_location']['lng'],
        ),
      )).toList(),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    // Google polyline decoding algorithm
    // Returns list of LatLng points
    // ...
  }
}
```

### ETA Refresh Strategy

| Scenario | Refresh Interval | Reason |
| -------- | --------------- | ------ |
| Order just picked up | Immediately | Initial ETA |
| During active delivery | Every 60 seconds | Traffic changes, route deviations |
| Partner significantly deviates | Immediately | Route recalculation needed |
| ETA < 5 minutes | Every 30 seconds | More precision for imminent arrival |

### ETA Display

```dart
@riverpod
class EtaNotifier extends _$EtaNotifier {
  Timer? _refreshTimer;

  @override
  Future<Duration> build(String orderId) async {
    ref.onDispose(() => _refreshTimer?.cancel());

    // Start periodic refresh
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => ref.invalidateSelf(),
    );

    final order = await ref.watch(watchOrderProvider(orderId).future);
    if (order.deliveryPartnerId == null) {
      return const Duration(minutes: 0);
    }

    final partnerLocation = await ref.watch(
      deliveryPartnerLocationProvider(order.deliveryPartnerId!).future,
    );

    final directions = await ref.watch(directionsServiceProvider).getRoute(
      origin: LatLng(
        partnerLocation.location.latitude,
        partnerLocation.location.longitude,
      ),
      destination: LatLng(
        order.deliveryAddress.location.latitude,
        order.deliveryAddress.location.longitude,
      ),
    );

    return Duration(seconds: directions.durationSeconds);
  }
}
```

---

## Background Location

### Android: Foreground Service

Android requires a foreground service with a persistent notification for continuous background location access.

```dart
// Using flutter_background_service or workmanager

// AndroidManifest.xml permissions:
// <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
// <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
// <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
// <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
```

**Persistent notification:**
```
+------------------------------------------+
|  Tuish Food                              |
|  You're online and ready for deliveries  |
|  [Go Offline]                            |
+------------------------------------------+
```

### iOS: Background Modes

```xml
<!-- ios/Runner/Info.plist -->
<key>UIBackgroundModes</key>
<array>
  <string>location</string>
  <string>fetch</string>
  <string>remote-notification</string>
</array>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Tuish Food needs your location to show customers where their delivery is and to match you with nearby orders.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Tuish Food needs your location to find nearby delivery orders.</string>
```

### Battery Optimization

| Technique | Implementation |
| --------- | -------------- |
| Adaptive interval | Increase update interval when idle, decrease during active delivery |
| Distance filter | Only process updates when partner has moved > 10m (active) or > 50m (idle) |
| Batch writes | Queue location updates and write to Firestore in batches if network is slow |
| Stop on offline | Completely stop tracking when partner goes offline |
| Reduce accuracy | Use `LocationAccuracy.balanced` when idle instead of `high` |

---

## Privacy Considerations

| Concern | Implementation |
| ------- | -------------- |
| Track only when online | Location tracking starts only when partner toggles online |
| Track only during delivery | Customer can only see partner location when order status is `pickedUp` |
| Clear location on offline | `delivery_locations` document updated with `isOnline: false` |
| No location history | Only current location is stored; no historical breadcrumb trail |
| Customer location | Stored only in order document, not tracked in real-time |
| Data retention | `cleanupOldLocations` scheduled function removes stale location data |
| Consent | Location permission requested with clear explanation of why it's needed |

---

## Delivery Partner Assignment Algorithm

When a new order is created, the system assigns the best available delivery partner.

### Algorithm Steps

```
1. Get restaurant location from order
     |
     v
2. Compute geohash of restaurant location
     |
     v
3. Query delivery_locations:
   - isOnline == true
   - currentOrderId == null (not on a delivery)
   - geohash in [center + 8 neighbors]
     |
     v
4. Filter results by Haversine distance <= maxDeliveryRadius
     |
     v
5. No partners found?
   +-- Yes --> Expand search radius (2x), retry once
   |           If still none --> Mark order as "awaiting partner"
   |           Retry every 60 seconds for 10 minutes
   +-- No --> Continue
     |
     v
6. Sort candidates by:
   - Primary: Distance to restaurant (ascending)
   - Tiebreaker: Partner rating (descending)
     |
     v
7. Send notification to top candidate
     |
     v
8. Wait 30 seconds for acceptance
     |
     v
9. Accepted?
   +-- Yes --> Assign partner to order
   +-- No  --> Remove candidate, go to step 7 with next candidate
     |
     v
10. All candidates exhausted?
    +-- Go to step 5 (expand radius / retry)
```

### Haversine Distance Calculation

```dart
double haversineDistance(GeoPoint a, GeoPoint b) {
  const earthRadiusKm = 6371.0;

  final dLat = _toRadians(b.latitude - a.latitude);
  final dLon = _toRadians(b.longitude - a.longitude);

  final aLat = _toRadians(a.latitude);
  final bLat = _toRadians(b.latitude);

  final h = sin(dLat / 2) * sin(dLat / 2) +
      cos(aLat) * cos(bLat) * sin(dLon / 2) * sin(dLon / 2);

  final c = 2 * asin(sqrt(h));

  return earthRadiusKm * c;
}

double _toRadians(double degrees) => degrees * pi / 180;
```

### Assignment Timeout Handling

```typescript
// Cloud Function: Timeout handler for partner assignment
// Uses Firestore TTL or scheduled task

async function handleAssignmentTimeout(orderId: string, partnerId: string) {
  const orderRef = admin.firestore().doc(`orders/${orderId}`);
  const order = await orderRef.get();

  // Check if still waiting for this partner
  if (order.data()?.pendingPartnerId === partnerId) {
    // Partner didn't respond in time
    await orderRef.update({
      pendingPartnerId: admin.firestore.FieldValue.delete(),
      assignmentAttempts: admin.firestore.FieldValue.increment(1),
    });

    // Try next partner
    await assignNextPartner(orderId);
  }
}
```
