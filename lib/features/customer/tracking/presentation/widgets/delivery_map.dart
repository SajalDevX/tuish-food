import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/features/customer/tracking/domain/entities/delivery_location.dart';

class DeliveryMap extends StatefulWidget {
  const DeliveryMap({
    super.key,
    this.deliveryLocation,
    this.restaurantLatLng,
    this.customerLatLng,
  });

  final DeliveryLocation? deliveryLocation;
  final LatLng? restaurantLatLng;
  final LatLng? customerLatLng;

  @override
  State<DeliveryMap> createState() => _DeliveryMapState();
}

class _DeliveryMapState extends State<DeliveryMap> {
  final Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(28.6139, 77.2090), // Default: New Delhi
    zoom: 14,
  );

  Set<Marker> get _markers {
    final markers = <Marker>{};

    // Delivery partner marker
    if (widget.deliveryLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('delivery_partner'),
          position: LatLng(
            widget.deliveryLocation!.latitude,
            widget.deliveryLocation!.longitude,
          ),
          rotation: widget.deliveryLocation!.heading,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: const InfoWindow(title: 'Delivery Partner'),
        ),
      );
    }

    // Restaurant marker
    if (widget.restaurantLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('restaurant'),
          position: widget.restaurantLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          infoWindow: const InfoWindow(title: 'Restaurant'),
        ),
      );
    }

    // Customer marker
    if (widget.customerLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: widget.customerLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Delivery Address'),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> get _polylines {
    final polylines = <Polyline>{};
    final points = <LatLng>[];

    if (widget.restaurantLatLng != null) {
      points.add(widget.restaurantLatLng!);
    }
    if (widget.deliveryLocation != null) {
      points.add(LatLng(
        widget.deliveryLocation!.latitude,
        widget.deliveryLocation!.longitude,
      ));
    }
    if (widget.customerLatLng != null) {
      points.add(widget.customerLatLng!);
    }

    if (points.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: AppColors.primary,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }

    return polylines;
  }

  @override
  void didUpdateWidget(covariant DeliveryMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.deliveryLocation != null &&
        (oldWidget.deliveryLocation?.latitude !=
                widget.deliveryLocation!.latitude ||
            oldWidget.deliveryLocation?.longitude !=
                widget.deliveryLocation!.longitude)) {
      _animateToLocation(
        widget.deliveryLocation!.latitude,
        widget.deliveryLocation!.longitude,
      );
    }
  }

  Future<void> _animateToLocation(double lat, double lng) async {
    if (_controller.isCompleted) {
      final controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newLatLng(LatLng(lat, lng)),
      );
    }
  }

  CameraPosition get _initialPosition {
    if (widget.deliveryLocation != null) {
      return CameraPosition(
        target: LatLng(
          widget.deliveryLocation!.latitude,
          widget.deliveryLocation!.longitude,
        ),
        zoom: 15,
      );
    }
    if (widget.customerLatLng != null) {
      return CameraPosition(target: widget.customerLatLng!, zoom: 15);
    }
    return _defaultPosition;
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: _initialPosition,
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (controller) {
        if (!_controller.isCompleted) {
          _controller.complete(controller);
        }
        // Fit bounds to show all markers
        _fitBounds(controller);
      },
    );
  }

  Future<void> _fitBounds(GoogleMapController controller) async {
    final allPoints = <LatLng>[];

    if (widget.deliveryLocation != null) {
      allPoints.add(LatLng(
        widget.deliveryLocation!.latitude,
        widget.deliveryLocation!.longitude,
      ));
    }
    if (widget.restaurantLatLng != null) {
      allPoints.add(widget.restaurantLatLng!);
    }
    if (widget.customerLatLng != null) {
      allPoints.add(widget.customerLatLng!);
    }

    if (allPoints.length >= 2) {
      double minLat = allPoints.first.latitude;
      double maxLat = allPoints.first.latitude;
      double minLng = allPoints.first.longitude;
      double maxLng = allPoints.first.longitude;

      for (final point in allPoints) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80),
      );
    }
  }
}
