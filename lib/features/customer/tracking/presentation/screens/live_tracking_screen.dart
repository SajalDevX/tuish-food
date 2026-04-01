import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/features/customer/orders/presentation/providers/order_provider.dart';
import 'package:tuish_food/features/customer/tracking/presentation/providers/tracking_provider.dart';
import 'package:tuish_food/features/customer/tracking/presentation/widgets/delivery_map.dart';
import 'package:tuish_food/features/customer/tracking/presentation/widgets/driver_info_card.dart';
import 'package:tuish_food/features/customer/tracking/presentation/widgets/eta_card.dart';
import 'package:tuish_food/routing/route_names.dart';

class LiveTrackingScreen extends ConsumerWidget {
  const LiveTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(watchOrderProvider(orderId));

    return Scaffold(
      appBar: const TuishAppBar(title: 'Live Tracking'),
      body: orderAsync.when(
        data: (order) {
          final partnerId = order.deliveryPartnerId;

          if (partnerId == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delivery_dining,
                    size: AppSizes.iconXL * 1.5,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: AppSizes.s16),
                  Text(
                    'Waiting for delivery partner...',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s8),
                  Text(
                    'A delivery partner will be assigned soon',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            );
          }

          final locationAsync =
              ref.watch(deliveryLocationProvider(partnerId));

          return Stack(
            children: [
              // Map
              Positioned.fill(
                bottom: 200,
                child: locationAsync.when(
                  data: (location) => DeliveryMap(
                    deliveryLocation: location,
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  ),
                  error: (_, _) => const DeliveryMap(),
                ),
              ),

              // Bottom cards
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ETA card
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.s16),
                      child: EtaCard(
                        status: order.status,
                        estimatedMinutes:
                            order.estimatedDeliveryTime
                                ?.difference(DateTime.now())
                                .inMinutes
                                .clamp(0, 999),
                      ),
                    ),

                    const SizedBox(height: AppSizes.s8),

                    // Driver info card
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppSizes.s16,
                        right: AppSizes.s16,
                        bottom: AppSizes.s16,
                      ),
                      child: DriverInfoCard(
                        driverName:
                            order.deliveryPartnerName ?? 'Delivery Partner',
                        onChatPressed: () {
                          context.pushNamed(
                            RouteNames.orderChat,
                            pathParameters: {'orderId': orderId},
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: AppSizes.iconXL, color: AppColors.error),
              const SizedBox(height: AppSizes.s16),
              Text(error.toString(),
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
