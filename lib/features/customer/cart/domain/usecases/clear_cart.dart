import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/cart/domain/entities/cart.dart';
import 'package:tuish_food/features/customer/cart/domain/repositories/cart_repository.dart';

class ClearCart {
  final CartRepository repository;

  const ClearCart(this.repository);

  Future<Either<Failure, Cart>> call() async {
    final result = await repository.clearCart();
    return result.fold((failure) => Left(failure), (_) => const Right(Cart()));
  }
}
