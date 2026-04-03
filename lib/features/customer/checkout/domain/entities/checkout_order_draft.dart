import 'package:equatable/equatable.dart';
import 'package:tuish_food/features/customer/cart/domain/entities/cart_item.dart';

class CheckoutOrderDraft extends Equatable {
  const CheckoutOrderDraft({
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
  });

  final String restaurantId;
  final String restaurantName;
  final List<CartItem> items;

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => [restaurantId, restaurantName, items];
}
