import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  final String menuItemId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final Map<String, List<String>> selectedCustomizations;

  const CartItem({
    required this.menuItemId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.selectedCustomizations = const {},
  });

  double get totalPrice => price * quantity;

  /// Creates a unique key for this cart item based on its menu item ID
  /// and selected customizations, so the same item with different
  /// customizations is tracked separately.
  String get uniqueKey {
    final customizationKey =
        selectedCustomizations.entries
            .map((e) => '${e.key}:${(e.value..sort()).join(',')}')
            .toList()
          ..sort();
    return '$menuItemId|${customizationKey.join('|')}';
  }

  CartItem copyWith({
    String? menuItemId,
    String? name,
    String? imageUrl,
    double? price,
    int? quantity,
    Map<String, List<String>>? selectedCustomizations,
  }) {
    return CartItem(
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      selectedCustomizations:
          selectedCustomizations ?? this.selectedCustomizations,
    );
  }

  @override
  List<Object?> get props => [
    menuItemId,
    name,
    imageUrl,
    price,
    quantity,
    selectedCustomizations,
  ];
}
