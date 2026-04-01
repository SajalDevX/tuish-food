import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tuish_food/core/constants/app_colors.dart';

/// A Google Map widget configured for delivery navigation.
///
/// Displays the driver's current location, destination marker, and a
/// polyline route between them.
class NavigationMap extends StatelessWidget {
  const NavigationMap({
    super.key,
    required this.currentPosition,
    required this.destinationPosition,
    required this.destinationLabel,
    this.polylinePoints = const [],
    this.onMapCreated,
  });

  final LatLng currentPosition;
  final LatLng destinationPosition;
  final String destinationLabel;
  final List<LatLng> polylinePoints;
  final void Function(GoogleMapController)? onMapCreated;

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('driver'),
        position: currentPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
        infoWindow: const InfoWindow(title: 'You'),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: destinationPosition,
        infoWindow: InfoWindow(title: destinationLabel),
      ),
    };

    final polylines = <Polyline>{};
    if (polylinePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: AppColors.secondary,
          width: 5,
        ),
      );
    }

    // Calculate bounds to fit both markers.
    final bounds = LatLngBounds(
      southwest: LatLng(
        currentPosition.latitude < destinationPosition.latitude
            ? currentPosition.latitude
            : destinationPosition.latitude,
        currentPosition.longitude < destinationPosition.longitude
            ? currentPosition.longitude
            : destinationPosition.longitude,
      ),
      northeast: LatLng(
        currentPosition.latitude > destinationPosition.latitude
            ? currentPosition.latitude
            : destinationPosition.latitude,
        currentPosition.longitude > destinationPosition.longitude
            ? currentPosition.longitude
            : destinationPosition.longitude,
      ),
    );

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: currentPosition,
        zoom: 14,
      ),
      markers: markers,
      polylines: polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (controller) {
        onMapCreated?.call(controller);
        // Fit both markers into view.
        controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 80),
        );
      },
    );
  }
}
