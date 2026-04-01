import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/utils/formatters.dart';
import 'package:tuish_food/core/widgets/confirmation_dialog.dart';
import 'package:tuish_food/core/widgets/error_widget.dart';
import 'package:tuish_food/core/widgets/loading_overlay.dart';
import 'package:tuish_food/core/widgets/status_badge.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_card.dart';
import 'package:tuish_food/features/delivery/dashboard/domain/entities/delivery_order.dart';
import 'package:tuish_food/features/delivery/dashboard/presentation/providers/delivery_dashboard_provider.dart';
import 'package:tuish_food/features/delivery/dashboard/presentation/widgets/status_update_button.dart';
import 'package:url_launcher/url_launcher.dart';

class ActiveDeliveryScreen extends ConsumerStatefulWidget {
  const ActiveDeliveryScreen({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  ConsumerState<ActiveDeliveryScreen> createState() =>
      _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends ConsumerState<ActiveDeliveryScreen> {
  bool _isUpdating = false;

  Future<void> _handleStatusUpdate(DeliveryOrder order) async {
    final OrderStatus nextStatus;
    final String confirmMessage;

    switch (order.status) {
      case OrderStatus.readyForPickup:
        // Navigate to restaurant
        context.go('/delivery/orders/${order.orderId}/navigate');
        return;
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

    return Scaffold(
      appBar: TuishAppBar(
        title: AppStrings.activeDelivery,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_outlined),
            onPressed: () =>
                context.go('/delivery/orders/${widget.orderId}/chat'),
          ),
        ],
      ),
      body: activeDelivery.when(
        data: (order) {
          if (order == null) {
            return const TuishErrorWidget(
              message: 'No active delivery found',
            );
          }

          return LoadingOverlay(
            isLoading: _isUpdating,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: AppSizes.screenPadding,
                    children: [
                      // Map preview
                      ClipRRect(
                        borderRadius: AppSizes.borderRadiusM,
                        child: SizedBox(
                          height: 200,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                order.restaurantLat,
                                order.restaurantLng,
                              ),
                              zoom: 14,
                            ),
                            markers: {
                              Marker(
                                markerId:
                                    const MarkerId('restaurant'),
                                position: LatLng(
                                  order.restaurantLat,
                                  order.restaurantLng,
                                ),
                                infoWindow: InfoWindow(
                                  title: order.restaurantName,
                                ),
                              ),
                              Marker(
                                markerId:
                                    const MarkerId('customer'),
                                position: LatLng(
                                  order.customerLat,
                                  order.customerLng,
                                ),
                                infoWindow: InfoWindow(
                                  title: order.customerName,
                                ),
                                icon: BitmapDescriptor
                                    .defaultMarkerWithHue(
                                  BitmapDescriptor.hueGreen,
                                ),
                              ),
                            },
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                            liteModeEnabled: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.s16),

                      // Order info header
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order.orderNumber}',
                            style: AppTypography.titleMedium,
                          ),
                          StatusBadge(status: order.status),
                        ],
                      ),
                      const SizedBox(height: AppSizes.s16),

                      // Restaurant pickup info
                      _LocationCard(
                        title: 'Pickup from',
                        name: order.restaurantName,
                        address: order.restaurantAddress,
                        icon: Icons.restaurant,
                        iconColor: AppColors.primary,
                        onCall: () => _launchPhone(''),
                        onNavigate: () => context.go(
                          '/delivery/orders/${order.orderId}/navigate',
                        ),
                      ),
                      const SizedBox(height: AppSizes.s12),

                      // Customer delivery info
                      _LocationCard(
                        title: 'Deliver to',
                        name: order.customerName,
                        address: order.customerAddress,
                        icon: Icons.person,
                        iconColor: AppColors.secondary,
                        onCall: () => _launchPhone(''),
                        onNavigate: () => context.go(
                          '/delivery/orders/${order.orderId}/navigate',
                        ),
                      ),
                      const SizedBox(height: AppSizes.s16),

                      // Order details
                      TuishCard(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Details',
                              style: AppTypography.titleSmall,
                            ),
                            const SizedBox(height: AppSizes.s8),
                            _DetailRow(
                              label: 'Items',
                              value: '${order.itemsCount} items',
                            ),
                            _DetailRow(
                              label: 'Distance',
                              value: Formatters.formatDistance(
                                  order.distanceKm),
                            ),
                            _DetailRow(
                              label: 'Delivery Fee',
                              value: Formatters.formatCurrency(
                                  order.deliveryFee),
                            ),
                            _DetailRow(
                              label: 'Order Total',
                              value: Formatters.formatCurrency(
                                  order.totalAmount),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.s24),
                    ],
                  ),
                ),

                // Status update button (pinned at bottom)
                Padding(
                  padding: AppSizes.paddingAllM,
                  child: StatusUpdateButton(
                    currentStatus: order.status,
                    isLoading: _isUpdating,
                    onPressed: () => _handleStatusUpdate(order),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
        error: (error, _) => TuishErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(activeDeliveryProvider),
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.title,
    required this.name,
    required this.address,
    required this.icon,
    required this.iconColor,
    required this.onCall,
    required this.onNavigate,
  });

  final String title;
  final String name;
  final String address;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onCall;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return TuishCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.bodySmall),
          const SizedBox(height: AppSizes.s8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: AppSizes.borderRadiusS,
                ),
                child: Icon(icon, color: iconColor, size: AppSizes.iconM),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.titleSmall),
                    Text(
                      address,
                      style: AppTypography.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.phone_outlined, size: AppSizes.iconS),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: iconColor,
                    side: BorderSide(color: iconColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSizes.borderRadiusS,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.s8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(
                    Icons.navigation_outlined,
                    size: AppSizes.iconS,
                  ),
                  label: const Text('Navigate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: iconColor,
                    side: BorderSide(color: iconColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSizes.borderRadiusS,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
