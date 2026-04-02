import 'package:equatable/equatable.dart';
import 'package:tuish_food/core/enums/payment_status.dart';

enum PaymentMethod {
  razorpay,
  cashOnDelivery;

  String get displayName {
    return switch (this) {
      PaymentMethod.razorpay => 'Pay Online',
      PaymentMethod.cashOnDelivery => 'Cash on Delivery',
    };
  }

  String get firestoreValue => name;

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (m) => m.name == value,
      orElse: () => PaymentMethod.cashOnDelivery,
    );
  }
}

class Payment extends Equatable {
  final String id;
  final PaymentMethod method;
  final PaymentStatus status;
  final double amount;
  final String? transactionId;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpaySignature;

  const Payment({
    required this.id,
    required this.method,
    required this.status,
    required this.amount,
    this.transactionId,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
  });

  @override
  List<Object?> get props => [
        id,
        method,
        status,
        amount,
        transactionId,
        razorpayOrderId,
        razorpayPaymentId,
        razorpaySignature,
      ];
}
