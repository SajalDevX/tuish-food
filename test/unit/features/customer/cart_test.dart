import 'package:flutter_test/flutter_test.dart';
import 'package:tuish_food/features/customer/cart/domain/entities/cart.dart';
import 'package:tuish_food/features/customer/cart/domain/entities/cart_item.dart';

void main() {
  const item1 = CartItem(
    menuItemId: 'item-1',
    name: 'Burger',
    imageUrl: 'https://example.com/burger.jpg',
    price: 199.0,
    quantity: 2,
  );

  const item2 = CartItem(
    menuItemId: 'item-2',
    name: 'Fries',
    imageUrl: 'https://example.com/fries.jpg',
    price: 99.0,
    quantity: 1,
  );

  group('CartItem', () {
    test('totalPrice is price * quantity', () {
      expect(item1.totalPrice, 398.0);
      expect(item2.totalPrice, 99.0);
    });

    test('uniqueKey uses menuItemId when no customizations', () {
      expect(item1.uniqueKey, contains('item-1'));
    });

    test('uniqueKey differs with different customizations', () {
      final customized = item1.copyWith(
        selectedCustomizations: {
          'size': ['Large'],
        },
      );
      expect(customized.uniqueKey, isNot(equals(item1.uniqueKey)));
    });

    test('supports value equality', () {
      const duplicate = CartItem(
        menuItemId: 'item-1',
        name: 'Burger',
        imageUrl: 'https://example.com/burger.jpg',
        price: 199.0,
        quantity: 2,
      );
      expect(item1, equals(duplicate));
    });

    test('copyWith creates modified copy', () {
      final updated = item1.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.menuItemId, item1.menuItemId);
      expect(updated.price, item1.price);
    });
  });

  group('Cart', () {
    const emptyCart = Cart();
    final fullCart = Cart(
      restaurantId: 'rest-1',
      restaurantName: 'Test Restaurant',
      items: [item1, item2],
    );

    test('isEmpty is true for empty cart', () {
      expect(emptyCart.isEmpty, isTrue);
      expect(emptyCart.isNotEmpty, isFalse);
    });

    test('isNotEmpty is true for cart with items', () {
      expect(fullCart.isNotEmpty, isTrue);
      expect(fullCart.isEmpty, isFalse);
    });

    test('subtotal sums item totals', () {
      // item1: 199*2=398, item2: 99*1=99 => 497
      expect(fullCart.subtotal, 497.0);
    });

    test('itemCount sums quantities', () {
      // item1: 2, item2: 1 => 3
      expect(fullCart.itemCount, 3);
    });

    test('empty cart has zero subtotal and itemCount', () {
      expect(emptyCart.subtotal, 0.0);
      expect(emptyCart.itemCount, 0);
    });

    test('copyWith creates modified copy', () {
      final updated = fullCart.copyWith(restaurantName: 'New Name');
      expect(updated.restaurantName, 'New Name');
      expect(updated.restaurantId, fullCart.restaurantId);
      expect(updated.items, fullCart.items);
    });

    test('supports value equality', () {
      final duplicate = Cart(
        restaurantId: 'rest-1',
        restaurantName: 'Test Restaurant',
        items: [item1, item2],
      );
      expect(fullCart, equals(duplicate));
    });
  });
}
