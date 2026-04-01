import 'package:equatable/equatable.dart';
import 'package:tuish_food/core/enums/payment_status.dart';

enum PaymentMethod {
  card,
  cashOnDelivery;

  String get displayName {
    return switch (this) {
      PaymentMethod.card => 'Card Payment',
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

  const Payment({
    required this.id,
    required this.method,
    required this.status,
    required this.amount,
    this.transactionId,
  });

  @override
  List<Object?> get props => [id, method, status, amount, transactionId];
}
