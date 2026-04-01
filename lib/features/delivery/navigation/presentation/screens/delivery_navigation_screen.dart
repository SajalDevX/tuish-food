import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/widgets/confirmation_dialog.dart';
import 'package:tuish_food/core/widgets/error_widget.dart';
import 'package:tuish_food/features/delivery/dashboard/presentation/providers/delivery_dashboard_provider.dart';
import 'package:tuish_food/features/delivery/navigation/presentation/providers/navigation_provider.dart';
import 'package:tuish_food/features/delivery/navigation/presentation/widgets/delivery_info_panel.dart';
import 'package:tuish_food/features/delivery/navigation/presentation/widgets/navigation_map.dart';
import 'package:tuish_food/features/delivery/navigation/presentation/widgets/turn_by_turn_card.dart';

class DeliveryNavigationScreen extends ConsumerStatefulWidget {
  const DeliveryNavigationScreen({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  ConsumerState<DeliveryNavigationScreen> createState() =>
      _DeliveryNavigationScreenState();
}

class _DeliveryNavigationScreenState
    extends ConsumerState<DeliveryNavigationScreen> {
  GoogleMapController? _mapController;
  bool _isUpdating = false;
  StreamSubscription<dynamic>? _locationSub;

  @override
  void initState() {
    super.initState();
    // Start tracking location updates to Firestore.
    _startLocationTracking();
  }

  void _startLocationTracking() {
    final stream = ref.read(currentLocationProvider.future).asStream();
    _locationSub = stream.listen(
      (position) {
        ref.read(navigationRepositoryProvider).updateDriverLocation(
              widget.orderId,
              position,
            );

        // Optionally move camera to follow driver.
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _handleStatusUpdate(OrderStatus currentStatus) async {
    final OrderStatus nextStatus;
    final String confirmMessage;

    switch (currentStatus) {
      case OrderStatus.pickedUp:
        nextStatus = OrderStatus.onTheWay;
        confirmMessage = 'Confirm that you have picked up the order?';
      case OrderStatus.onTheWay:
        nextStatus = OrderStatus.delivered;
        confirmMessage = 'Confirm that the order has been delivered?';
      default:
        return;
    }

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Update Status',
      message: confirmMessage,
      confirmLabel: AppStrings.confirm,
      cancelLabel: AppStrings.cancel,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isUpdating = true);

    final result = await ref
        .read(deliveryRepositoryProvider)
        .updateOrderStatus(widget.orderId, nextStatus);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (_) {
        setState(() => _isUpdating = false);
        ref.invalidate(activeDeliveryProvider);
        if (nextStatus == OrderStatus.delivered) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order delivered successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/delivery/home');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeDelivery = ref.watch(activeDeliveryProvider);
    final currentLocation = ref.watch(currentLocationProvider);

    return Scaffold(
      body: activeDelivery.when(
        data: (order) {
          if (order == null) {
            return const TuishErrorWidget(
              message: 'No active delivery found',
            );
          }

          final isHeadingToRestaurant =
              order.status == OrderStatus.pickedUp;
          final destLat = isHeadingToRestaurant
              ? order.restaurantLat
              : order.customerLat;
          final destLng = isHeadingToRestaurant
              ? order.restaurantLng
              : order.customerLng;
          final destName = isHeadingToRestaurant
              ? order.restaurantName
              : order.customerName;
          final destAddress = isHeadingToRestaurant
              ? order.restaurantAddress
              : order.customerAddress;
          final panelTitle = isHeadingToRestaurant
              ? 'Pickup from restaurant'
              : 'Deliver to customer';

          final routeProvider = isHeadingToRestaurant
              ? routeToRestaurantProvider(RouteParams(destLat, destLng))
              : routeToCustomerProvider(RouteParams(destLat, destLng));
          final routeData = ref.watch(routeProvider);

          return currentLocation.when(
            data: (position) {
              final driverPos = LatLng(
                position.latitude,
                position.longitude,
              );
              final destPos = LatLng(destLat, destLng);

              return Stack(
                children: [
                  // Full-screen map
                  NavigationMap(
                    currentPosition: driverPos,
                    destinationPosition: destPos,
                    destinationLabel: destName,
                    polylinePoints: routeData.when(
                      data: (route) => route.polylinePoints,
                      loading: () => <LatLng>[],
                      error: (_, _) => <LatLng>[],
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                  ),

                  // Back button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + AppSizes.s8,
                    left: AppSizes.s16,
                    child: CircleAvatar(
                      backgroundColor: AppColors.surface,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ),

                  // Turn-by-turn card at top
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 56,
                    left: 0,
                    right: 0,
                    child: routeData.when(
                      data: (route) => TurnByTurnCard(
                        distanceKm: route.distanceKm,
                        estimatedMinutes: route.estimatedMinutes,
                        destinationName: destName,
                        directionIcon: isHeadingToRestaurant
                            ? Icons.restaurant
                            : Icons.person,
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ),

                  // Bottom info panel
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: DeliveryInfoPanel(
                      title: panelTitle,
                      name: destName,
                      address: destAddress,
                      distanceKm: routeData.when(
                        data: (route) => route.distanceKm,
                        loading: () => order.distanceKm,
                        error: (_, _) => order.distanceKm,
                      ),
                      estimatedMinutes: routeData.when(
                        data: (route) => route.estimatedMinutes,
                        loading: () => 0,
                        error: (_, _) => 0,
                      ),
                      currentStatus: order.status,
                      isUpdating: _isUpdating,
                      onStatusUpdate: () =>
                          _handleStatusUpdate(order.status),
                    ),
                  ),

                  // Re-center button
                  Positioned(
                    bottom: 260,
                    right: AppSizes.s16,
                    child: FloatingActionButton.small(
                      heroTag: 'recenter',
                      backgroundColor: AppColors.surface,
                      onPressed: () {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLng(driverPos),
                        );
                      },
                      child: const Icon(
                        Icons.my_location,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            ),
            error: (e, _) => TuishErrorWidget(
              message: 'Unable to get your location.\n$e',
              onRetry: () => ref.invalidate(currentLocationProvider),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
        error: (e, _) => TuishErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(activeDeliveryProvider),
        ),
      ),
    );
  }
}
