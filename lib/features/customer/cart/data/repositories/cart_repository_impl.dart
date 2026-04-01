import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/cart/data/models/cart_item_model.dart';
import 'package:tuish_food/features/customer/cart/domain/entities/cart.dart';
import 'package:tuish_food/features/customer/cart/domain/repositories/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  static const _cartKey = 'tuish_cart';

  final SharedPreferences sharedPreferences;

  const CartRepositoryImpl({required this.sharedPreferences});

  @override
  Future<Either<Failure, Cart>> getCart() async {
    try {
      final jsonString = sharedPreferences.getString(_cartKey);
      if (jsonString == null) return const Right(Cart());

      final data = json.decode(jsonString) as Map<String, dynamic>;
      final items =
          (data['items'] as List<dynamic>?)
              ?.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      return Right(
        Cart(
          restaurantId: data['restaurantId'] as String?,
          restaurantName: data['restaurantName'] as String?,
          items: items,
        ),
      );
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to load cart: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveCart(Cart cart) async {
    try {
      final data = {
        'restaurantId': cart.restaurantId,
        'restaurantName': cart.restaurantName,
        'items': cart.items
            .map((item) => CartItemModel.fromEntity(item).toJson())
            .toList(),
      };

      await sharedPreferences.setString(_cartKey, json.encode(data));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to save cart: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearCart() async {
    try {
      await sharedPreferences.remove(_cartKey);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to clear cart: $e'));
    }
  }
}
