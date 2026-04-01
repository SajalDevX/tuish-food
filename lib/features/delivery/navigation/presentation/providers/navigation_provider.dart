import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tuish_food/core/services/location_service.dart';
import 'package:tuish_food/features/delivery/navigation/data/repositories/navigation_repository_impl.dart';
import 'package:tuish_food/features/delivery/navigation/domain/repositories/navigation_repository.dart';
import 'package:tuish_food/injection_container.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final navigationRepositoryProvider = Provider<NavigationRepository>((ref) {
  return NavigationRepositoryImpl(
    firestore: ref.watch(firestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
    locationService: ref.watch(locationServiceProvider),
  );
});

// ---------------------------------------------------------------------------
// Current location stream
// ---------------------------------------------------------------------------

final currentLocationProvider = StreamProvider<Position>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getLocationStream(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );
});

// ---------------------------------------------------------------------------
// Route to restaurant
// ---------------------------------------------------------------------------

class RouteParams {
  final double lat;
  final double lng;
  const RouteParams(this.lat, this.lng);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteParams && lat == other.lat && lng == other.lng;

  @override
  int get hashCode => lat.hashCode ^ lng.hashCode;
}

final routeToRestaurantProvider =
    FutureProvider.family<RouteInfo, RouteParams>((ref, params) async {
  final repository = ref.watch(navigationRepositoryProvider);
  final result = await repository.getRouteToRestaurant(params.lat, params.lng);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (route) => route,
  );
});

// ---------------------------------------------------------------------------
// Route to customer
// ---------------------------------------------------------------------------

final routeToCustomerProvider =
    FutureProvider.family<RouteInfo, RouteParams>((ref, params) async {
  final repository = ref.watch(navigationRepositoryProvider);
  final result = await repository.getRouteToCustomer(params.lat, params.lng);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (route) => route,
  );
});

// ---------------------------------------------------------------------------
// Navigation state
// ---------------------------------------------------------------------------

enum NavigationTarget { restaurant, customer }

class NavigationTargetNotifier extends Notifier<NavigationTarget> {
  @override
  NavigationTarget build() => NavigationTarget.restaurant;

  void update(NavigationTarget value) {
    state = value;
  }
}

final navigationTargetProvider =
    NotifierProvider<NavigationTargetNotifier, NavigationTarget>(
        NavigationTargetNotifier.new);
