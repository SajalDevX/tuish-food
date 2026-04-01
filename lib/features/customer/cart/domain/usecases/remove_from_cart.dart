import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/cart/domain/entities/cart.dart';
import 'package:tuish_food/features/customer/cart/domain/repositories/cart_repository.dart';

class RemoveFromCart {
  final CartRepository repository;

  const RemoveFromCart(this.repository);

  /// Removes the cart item at the given [uniqueKey].
  Future<Either<Failure, Cart>> call({
    required Cart currentCart,
    required String uniqueKey,
  }) async {
    final updatedItems = currentCart.items
        .where((i) => i.uniqueKey != uniqueKey)
        .toList();

    final updatedCart = updatedItems.isEmpty
        ? const Cart()
        : currentCart.copyWith(items: updatedItems);

    final saveResult = await repository.saveCart(updatedCart);
    return saveResult.fold(
      (failure) => Left(failure),
      (_) => Right(updatedCart),
    );
  }
}
