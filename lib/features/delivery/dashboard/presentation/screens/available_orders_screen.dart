import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/core/widgets/error_widget.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/features/delivery/dashboard/presentation/providers/delivery_dashboard_provider.dart';
import 'package:tuish_food/features/delivery/dashboard/presentation/widgets/delivery_order_card.dart';
import 'package:tuish_food/features/delivery/dashboard/presentation/widgets/order_accept_sheet.dart';

class AvailableOrdersScreen extends ConsumerWidget {
  const AvailableOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableOrders = ref.watch(availableOrdersProvider);

    return Scaffold(
      appBar: const TuishAppBar(title: AppStrings.availableOrders),
      body: availableOrders.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const EmptyStateWidget(
              message: 'No orders available right now.\nNew orders will appear here automatically.',
              icon: Icons.delivery_dining_outlined,
            );
          }

          return ListView.builder(
            padding: AppSizes.screenPadding,
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return DeliveryOrderCard(
                order: order,
                onAccept: () {
                  OrderAcceptSheet.show(
                    context,
                    order: order,
                    onAccept: () {
                      ref.read(
                        acceptOrderProvider(order.orderId),
                      );
                      // Refresh active delivery
                      ref.invalidate(activeDeliveryProvider);
                    },
                    onReject: () {
                      ref.read(deliveryRepositoryProvider).rejectOrder(
                            order.orderId,
                          );
                    },
                  );
                },
                onReject: () {
                  ref.read(deliveryRepositoryProvider).rejectOrder(
                        order.orderId,
                      );
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
        error: (error, _) => TuishErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(availableOrdersProvider),
        ),
      ),
    );
  }
}
