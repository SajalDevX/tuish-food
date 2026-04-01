import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/checkout/domain/entities/payment.dart';
import 'package:tuish_food/features/customer/checkout/domain/repositories/checkout_repository.dart';

class ProcessPayment {
  final CheckoutRepository repository;

  const ProcessPayment(this.repository);

  Future<Either<Failure, Payment>> call({
    required String orderId,
    required PaymentMethod method,
    required double amount,
  }) {
    return repository.processPayment(
      orderId: orderId,
      method: method,
      amount: amount,
    );
  }
}
