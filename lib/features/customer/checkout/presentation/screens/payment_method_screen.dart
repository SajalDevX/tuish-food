import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/features/customer/checkout/domain/entities/payment.dart';
import 'package:tuish_food/features/customer/checkout/presentation/providers/checkout_provider.dart';
import 'package:tuish_food/features/customer/checkout/presentation/widgets/payment_method_tile.dart';

class PaymentMethodScreen extends ConsumerStatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  ConsumerState<PaymentMethodScreen> createState() =>
      _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen> {
  late PaymentMethod _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = ref.read(checkoutNotifierProvider).paymentMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Method'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: AppSizes.paddingAllM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose how you would like to pay',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSizes.s24),

            PaymentMethodTile(
              method: PaymentMethod.cashOnDelivery,
              isSelected: _selectedMethod == PaymentMethod.cashOnDelivery,
              onTap: () => setState(
                () => _selectedMethod = PaymentMethod.cashOnDelivery,
              ),
            ),
            const SizedBox(height: AppSizes.s12),

            PaymentMethodTile(
              method: PaymentMethod.razorpay,
              isSelected: _selectedMethod == PaymentMethod.razorpay,
              onTap: () =>
                  setState(() => _selectedMethod = PaymentMethod.razorpay),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: AppSizes.paddingAllM,
          child: TuishButton.primary(
            label: 'Confirm',
            onPressed: () {
              ref
                  .read(checkoutNotifierProvider.notifier)
                  .setPaymentMethod(_selectedMethod);
              context.pop();
            },
          ),
        ),
      ),
    );
  }
}
