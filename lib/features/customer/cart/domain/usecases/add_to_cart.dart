import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/cart/domain/entities/cart.dart';
import 'package:tuish_food/features/customer/cart/domain/entities/cart_item.dart';
import 'package:tuish_food/features/customer/cart/domain/repositories/cart_repository.dart';

class AddToCart {
  final CartRepository repository;

  const AddToCart(this.repository);

  Future<Either<Failure, Cart>> call({
    required Cart currentCart,
    required CartItem item,
    required String restaurantId,
    required String restaurantName,
  }) async {
    final updatedItems = List<CartItem>.from(currentCart.items);

    // Find existing item with same unique key
    final existingIndex = updatedItems.indexWhere(
      (i) => i.uniqueKey == item.uniqueKey,
    );

    if (existingIndex >= 0) {
      final existing = updatedItems[existingIndex];
      updatedItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + item.quantity,
      );
    } else {
      updatedItems.add(item);
    }

    final updatedCart = Cart(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      items: updatedItems,
    );

    final saveResult = await repository.saveCart(updatedCart);
    return saveResult.fold(
      (failure) => Left(failure),
      (_) => Right(updatedCart),
    );
  }
}
