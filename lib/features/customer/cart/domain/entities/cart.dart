import 'package:equatable/equatable.dart';
import 'package:tuish_food/features/customer/cart/domain/entities/cart_item.dart';

class Cart extends Equatable {
  final String? restaurantId;
  final String? restaurantName;
  final List<CartItem> items;

  const Cart({this.restaurantId, this.restaurantName, this.items = const []});

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  Cart copyWith({
    String? restaurantId,
    String? restaurantName,
    List<CartItem>? items,
  }) {
    return Cart(
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [restaurantId, restaurantName, items];
}
