import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/utils/formatters.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/routing/route_names.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final orderNumber = Formatters.formatOrderNumber(orderId);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSizes.paddingAllL,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Success icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 64,
                ),
              ),
              const SizedBox(height: AppSizes.s24),

              // Title
              Text(
                AppStrings.orderPlaced,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppSizes.s8),

              // Subtitle
              Text(
                'Your order has been placed successfully!',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.s24),

              // Order number card
              Container(
                padding: AppSizes.paddingAllM,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: AppSizes.borderRadiusM,
                ),
                child: Column(
                  children: [
                    Text('Order Number', style: AppTypography.bodySmall),
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      orderNumber,
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.s16),

              // ETA
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s16,
                  vertical: AppSizes.s12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: AppSizes.borderRadiusM,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSizes.s8),
                    Text(
                      'Estimated delivery: 30-45 min',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Track Order button
              TuishButton.primary(
                label: AppStrings.trackOrder,
                onPressed: () {
                  context.goNamed(
                    RouteNames.orderDetail,
                    pathParameters: {'orderId': orderId},
                  );
                },
              ),
              const SizedBox(height: AppSizes.s12),

              // Back to Home
              TuishButton.outlined(
                label: 'Back to Home',
                onPressed: () {
                  context.goNamed(RouteNames.customerHome);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
