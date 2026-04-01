import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/checkout/domain/entities/payment.dart';

class PlaceOrderParams {
  final String restaurantId;
  final String restaurantName;
  final List<OrderItemParam> items;
  final String deliveryAddressId;
  final String deliveryAddress;
  final PaymentMethod paymentMethod;
  final double subtotal;
  final double deliveryFee;
  final double taxes;
  final double tip;
  final double discount;
  final double total;
  final String? couponCode;
  final String? specialInstructions;

  const PlaceOrderParams({
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
    required this.deliveryAddressId,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryFee,
    required this.taxes,
    required this.tip,
    required this.discount,
    required this.total,
    this.couponCode,
    this.specialInstructions,
  });
}

class OrderItemParam {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final Map<String, List<String>> selectedCustomizations;

  const OrderItemParam({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.selectedCustomizations = const {},
  });
}

class CouponResult {
  final String code;
  final double discountAmount;
  final String description;

  const CouponResult({
    required this.code,
    required this.discountAmount,
    required this.description,
  });
}

abstract class CheckoutRepository {
  Future<Either<Failure, String>> placeOrder(PlaceOrderParams params);
  Future<Either<Failure, CouponResult>> applyCoupon({
    required String code,
    required double subtotal,
  });
  Future<Either<Failure, Payment>> processPayment({
    required String orderId,
    required PaymentMethod method,
    required double amount,
  });
}
