import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuish_food/features/customer/checkout/data/datasources/payment_remote_datasource.dart';
import 'package:tuish_food/features/customer/checkout/data/repositories/checkout_repository_impl.dart';
import 'package:tuish_food/features/customer/checkout/domain/entities/payment.dart';
import 'package:tuish_food/features/customer/checkout/domain/repositories/checkout_repository.dart';
import 'package:tuish_food/injection_container.dart';

// ---------------------------------------------------------------------------
// Repository wiring
// ---------------------------------------------------------------------------

final paymentRemoteDatasourceProvider = Provider<PaymentRemoteDatasource>((
  ref,
) {
  return PaymentRemoteDatasourceImpl(
    firestore: ref.watch(firestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepositoryImpl(
    remoteDatasource: ref.watch(paymentRemoteDatasourceProvider),
  );
});

// ---------------------------------------------------------------------------
// Checkout state
// ---------------------------------------------------------------------------

class CheckoutState extends Equatable {
  final String? deliveryAddressId;
  final String? deliveryAddress;
  final PaymentMethod paymentMethod;
  final double tip;
  final double discount;
  final String? couponCode;
  final String? specialInstructions;
  final bool isPlacingOrder;
  final String? errorMessage;
  final String? placedOrderId;

  const CheckoutState({
    this.deliveryAddressId,
    this.deliveryAddress,
    this.paymentMethod = PaymentMethod.cashOnDelivery,
    this.tip = 0,
    this.discount = 0,
    this.couponCode,
    this.specialInstructions,
    this.isPlacingOrder = false,
    this.errorMessage,
    this.placedOrderId,
  });

  CheckoutState copyWith({
    String? deliveryAddressId,
    String? deliveryAddress,
    PaymentMethod? paymentMethod,
    double? tip,
    double? discount,
    String? couponCode,
    String? specialInstructions,
    bool? isPlacingOrder,
    String? errorMessage,
    String? placedOrderId,
  }) {
    return CheckoutState(
      deliveryAddressId: deliveryAddressId ?? this.deliveryAddressId,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      tip: tip ?? this.tip,
      discount: discount ?? this.discount,
      couponCode: couponCode ?? this.couponCode,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
      errorMessage: errorMessage,
      placedOrderId: placedOrderId,
    );
  }

  @override
  List<Object?> get props => [
    deliveryAddressId,
    deliveryAddress,
    paymentMethod,
    tip,
    discount,
    couponCode,
    specialInstructions,
    isPlacingOrder,
    errorMessage,
    placedOrderId,
  ];
}

// ---------------------------------------------------------------------------
// Checkout notifier
// ---------------------------------------------------------------------------

final checkoutNotifierProvider =
    NotifierProvider<CheckoutNotifier, CheckoutState>(CheckoutNotifier.new);

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  CheckoutRepository get _repository => ref.read(checkoutRepositoryProvider);

  void setDeliveryAddress(String id, String address) {
    state = state.copyWith(deliveryAddressId: id, deliveryAddress: address);
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setTip(double tip) {
    state = state.copyWith(tip: tip);
  }

  void setSpecialInstructions(String instructions) {
    state = state.copyWith(specialInstructions: instructions);
  }

  Future<void> applyCoupon(String code, double subtotal) async {
    final result = await _repository.applyCoupon(
      code: code,
      subtotal: subtotal,
    );

    result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
      },
      (couponResult) {
        state = state.copyWith(
          couponCode: couponResult.code,
          discount: couponResult.discountAmount,
          errorMessage: null,
        );
      },
    );
  }

  void removeCoupon() {
    state = state.copyWith(couponCode: null, discount: 0);
  }

  Future<String?> placeOrder(PlaceOrderParams params) async {
    state = state.copyWith(isPlacingOrder: true, errorMessage: null);

    final result = await _repository.placeOrder(params);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isPlacingOrder: false,
          errorMessage: failure.message,
        );
        return null;
      },
      (orderId) async {
        // Process payment
        final paymentResult = await _repository.processPayment(
          orderId: orderId,
          method: params.paymentMethod,
          amount: params.total,
        );

        return paymentResult.fold(
          (failure) {
            state = state.copyWith(
              isPlacingOrder: false,
              errorMessage: failure.message,
            );
            return null;
          },
          (payment) {
            state = state.copyWith(
              isPlacingOrder: false,
              placedOrderId: orderId,
            );
            return orderId;
          },
        );
      },
    );
  }

  void reset() {
    state = const CheckoutState();
  }
}
