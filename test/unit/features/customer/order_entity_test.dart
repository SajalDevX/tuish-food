import 'package:flutter_test/flutter_test.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/enums/payment_status.dart';
import 'package:tuish_food/features/customer/orders/domain/entities/order.dart';

void main() {
  final now = DateTime.now();

  final order = CustomerOrder(
    id: 'order-1',
    orderNumber: 'TF-20260331-ABCD',
    customerId: 'cust-1',
    restaurantId: 'rest-1',
    restaurantName: 'Test Restaurant',
    items: const [
      OrderItem(
        id: 'item-1',
        name: 'Burger',
        quantity: 2,
        price: 199.0,
        totalPrice: 398.0,
      ),
      OrderItem(
        id: 'item-2',
        name: 'Fries',
        quantity: 1,
        price: 99.0,
        totalPrice: 99.0,
      ),
    ],
    subtotal: 497.0,
    deliveryFee: 40.0,
    serviceFee: 25.0,
    tax: 24.85,
    totalAmount: 586.85,
    status: OrderStatus.preparing,
    paymentMethod: 'upi',
    paymentStatus: PaymentStatus.completed,
    createdAt: now,
    updatedAt: now,
  );

  group('CustomerOrder', () {
    test('isActive returns true for non-terminal status', () {
      expect(order.isActive, isTrue);
    });

    test('isTerminal returns false for active order', () {
      expect(order.isTerminal, isFalse);
    });

    test('totalItemCount sums item quantities', () {
      // 2 + 1 = 3
      expect(order.totalItemCount, 3);
    });

    test('supports value equality', () {
      final duplicate = CustomerOrder(
        id: 'order-1',
        orderNumber: 'TF-20260331-ABCD',
        customerId: 'cust-1',
        restaurantId: 'rest-1',
        restaurantName: 'Test Restaurant',
        items: const [
          OrderItem(
            id: 'item-1',
            name: 'Burger',
            quantity: 2,
            price: 199.0,
            totalPrice: 398.0,
          ),
          OrderItem(
            id: 'item-2',
            name: 'Fries',
            quantity: 1,
            price: 99.0,
            totalPrice: 99.0,
          ),
        ],
        subtotal: 497.0,
        deliveryFee: 40.0,
        serviceFee: 25.0,
        tax: 24.85,
        totalAmount: 586.85,
        status: OrderStatus.preparing,
        paymentMethod: 'upi',
        paymentStatus: PaymentStatus.completed,
        createdAt: now,
        updatedAt: now,
      );
      expect(order, equals(duplicate));
    });
  });

  group('OrderItem', () {
    test('supports value equality', () {
      const item = OrderItem(
        id: 'item-1',
        name: 'Burger',
        quantity: 2,
        price: 199.0,
        totalPrice: 398.0,
      );
      const duplicate = OrderItem(
        id: 'item-1',
        name: 'Burger',
        quantity: 2,
        price: 199.0,
        totalPrice: 398.0,
      );
      expect(item, equals(duplicate));
    });

    test('different ids produce inequality', () {
      const item1 = OrderItem(
        id: 'item-1',
        name: 'Burger',
        quantity: 1,
        price: 199.0,
        totalPrice: 199.0,
      );
      const item2 = OrderItem(
        id: 'item-2',
        name: 'Burger',
        quantity: 1,
        price: 199.0,
        totalPrice: 199.0,
      );
      expect(item1, isNot(equals(item2)));
    });
  });

  group('StatusHistoryEntry', () {
    test('supports value equality', () {
      final entry = StatusHistoryEntry(
        status: OrderStatus.placed,
        timestamp: now,
        note: 'Order placed',
      );
      final duplicate = StatusHistoryEntry(
        status: OrderStatus.placed,
        timestamp: now,
        note: 'Order placed',
      );
      expect(entry, equals(duplicate));
    });
  });
}
