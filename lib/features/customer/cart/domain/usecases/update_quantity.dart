import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/cart/domain/entities/cart.dart';
import 'package:tuish_food/features/customer/cart/domain/entities/cart_item.dart';
import 'package:tuish_food/features/customer/cart/domain/repositories/cart_repository.dart';

class UpdateQuantity {
  final CartRepository repository;

  const UpdateQuantity(this.repository);

  /// Updates the quantity of a cart item identified by [uniqueKey].
  /// If quantity reaches 0, the item is removed.
  Future<Either<Failure, Cart>> call({
    required Cart currentCart,
    required String uniqueKey,
    required int newQuantity,
  }) async {
    List<CartItem> updatedItems;

    if (newQuantity <= 0) {
      updatedItems = currentCart.items
          .where((i) => i.uniqueKey != uniqueKey)
          .toList();
    } else {
      updatedItems = currentCart.items.map((item) {
        if (item.uniqueKey == uniqueKey) {
          return item.copyWith(quantity: newQuantity);
        }
        return item;
      }).toList();
    }

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
