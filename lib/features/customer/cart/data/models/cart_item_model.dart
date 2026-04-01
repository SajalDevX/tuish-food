import 'package:tuish_food/features/customer/cart/domain/entities/cart_item.dart';

class CartItemModel extends CartItem {
  const CartItemModel({
    required super.menuItemId,
    required super.name,
    required super.imageUrl,
    required super.price,
    required super.quantity,
    super.selectedCustomizations,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      menuItemId: json['menuItemId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
      selectedCustomizations: _parseCustomizations(
        json['selectedCustomizations'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'selectedCustomizations': selectedCustomizations.map(
        (key, value) => MapEntry(key, value),
      ),
    };
  }

  factory CartItemModel.fromEntity(CartItem item) {
    return CartItemModel(
      menuItemId: item.menuItemId,
      name: item.name,
      imageUrl: item.imageUrl,
      price: item.price,
      quantity: item.quantity,
      selectedCustomizations: item.selectedCustomizations,
    );
  }

  static Map<String, List<String>> _parseCustomizations(dynamic data) {
    if (data == null) return {};
    if (data is Map) {
      return data.map((key, value) {
        final list =
            (value as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        return MapEntry(key.toString(), list);
      });
    }
    return {};
  }
}
