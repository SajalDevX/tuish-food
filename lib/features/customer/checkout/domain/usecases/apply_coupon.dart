import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/checkout/domain/repositories/checkout_repository.dart';

class ApplyCoupon {
  final CheckoutRepository repository;

  const ApplyCoupon(this.repository);

  Future<Either<Failure, CouponResult>> call({
    required String code,
    required double subtotal,
  }) {
    return repository.applyCoupon(code: code, subtotal: subtotal);
  }
}
