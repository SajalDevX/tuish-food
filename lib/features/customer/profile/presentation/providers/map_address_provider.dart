import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tuish_food/core/services/geocoding_service.dart';
import 'package:tuish_food/core/services/location_service.dart';

class MapAddressState {
  final LatLng? selectedLatLng;
  final PlacemarkResult? placemark;
  final bool isGeocodingLoading;
  final bool isGpsLoading;
  final String? geocodeError;

  const MapAddressState({
    this.selectedLatLng,
    this.placemark,
    this.isGeocodingLoading = false,
    this.isGpsLoading = false,
    this.geocodeError,
  });

  MapAddressState copyWith({
    LatLng? selectedLatLng,
    PlacemarkResult? placemark,
    bool? isGeocodingLoading,
    bool? isGpsLoading,
    String? geocodeError,
    bool clearError = false,
    bool clearPlacemark = false,
  }) {
    return MapAddressState(
      selectedLatLng: selectedLatLng ?? this.selectedLatLng,
      placemark: clearPlacemark ? null : (placemark ?? this.placemark),
      isGeocodingLoading: isGeocodingLoading ?? this.isGeocodingLoading,
      isGpsLoading: isGpsLoading ?? this.isGpsLoading,
      geocodeError: clearError ? null : (geocodeError ?? this.geocodeError),
    );
  }
}

class MapAddressNotifier extends Notifier<MapAddressState> {
  @override
  MapAddressState build() => const MapAddressState();

  /// Called when the map camera stops moving. Reverse-geocodes [center].
  Future<void> onCameraIdle(LatLng center) async {
    state = state.copyWith(
      selectedLatLng: center,
      isGeocodingLoading: true,
      clearError: true,
    );

    final result = await ref
        .read(geocodingServiceProvider)
        .reverseGeocode(center.latitude, center.longitude);

    state = state.copyWith(
      placemark: result,
      isGeocodingLoading: false,
      geocodeError: result == null ? 'Could not identify location' : null,
      clearPlacemark: result == null,
    );
  }

  /// Requests GPS location and moves the map to it.
  Future<void> useMyLocation() async {
    state = state.copyWith(isGpsLoading: true, clearError: true);
    try {
      final position = await ref
          .read(locationServiceProvider)
          .getCurrentLocation();
      // onCameraIdle will be triggered by the map after animateCamera,
      // but we also update selectedLatLng eagerly so callers can animate the camera.
      state = state.copyWith(
        selectedLatLng: LatLng(position.latitude, position.longitude),
        isGpsLoading: false,
      );
      // Reverse-geocode the GPS position.
      await onCameraIdle(LatLng(position.latitude, position.longitude));
    } on PermissionDeniedException {
      state = state.copyWith(
        isGpsLoading: false,
        geocodeError: 'Location permission denied',
      );
    } on LocationServiceDisabledException {
      state = state.copyWith(
        isGpsLoading: false,
        geocodeError: 'Location services are disabled',
      );
    } catch (e) {
      state = state.copyWith(
        isGpsLoading: false,
        geocodeError: 'Could not get location',
      );
    }
  }

  void reset() {
    state = const MapAddressState();
  }
}

final mapAddressProvider =
    NotifierProvider<MapAddressNotifier, MapAddressState>(
        MapAddressNotifier.new);
