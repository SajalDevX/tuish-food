import 'package:flutter_test/flutter_test.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/enums/payment_status.dart';
import 'package:tuish_food/core/enums/user_role.dart';

void main() {
  group('OrderStatus', () {
    test('displayName returns human-readable strings', () {
      expect(OrderStatus.placed.displayName, 'Order Placed');
      expect(OrderStatus.confirmed.displayName, 'Confirmed');
      expect(OrderStatus.preparing.displayName, 'Preparing');
      expect(OrderStatus.readyForPickup.displayName, 'Ready for Pickup');
      expect(OrderStatus.pickedUp.displayName, 'Picked Up');
      expect(OrderStatus.onTheWay.displayName, 'On the Way');
      expect(OrderStatus.delivered.displayName, 'Delivered');
      expect(OrderStatus.cancelled.displayName, 'Cancelled');
    });

    test('firestoreValue returns correct strings', () {
      expect(OrderStatus.placed.firestoreValue, 'placed');
      expect(OrderStatus.readyForPickup.firestoreValue, 'readyForPickup');
    });

    test('isActive returns true for non-terminal statuses', () {
      expect(OrderStatus.placed.isActive, isTrue);
      expect(OrderStatus.preparing.isActive, isTrue);
      expect(OrderStatus.delivered.isActive, isFalse);
      expect(OrderStatus.cancelled.isActive, isFalse);
    });

    test('isTerminal returns true for delivered and cancelled', () {
      expect(OrderStatus.delivered.isTerminal, isTrue);
      expect(OrderStatus.cancelled.isTerminal, isTrue);
      expect(OrderStatus.onTheWay.isTerminal, isFalse);
    });

    test('fromString parses known values', () {
      expect(OrderStatus.fromString('placed'), OrderStatus.placed);
      expect(OrderStatus.fromString('onTheWay'), OrderStatus.onTheWay);
    });

    test('fromString defaults to placed for unknown values', () {
      expect(OrderStatus.fromString('unknown'), OrderStatus.placed);
    });
  });

  group('PaymentStatus', () {
    test('displayName returns human-readable strings', () {
      expect(PaymentStatus.pending.displayName, 'Pending');
      expect(PaymentStatus.completed.displayName, 'Completed');
      expect(PaymentStatus.failed.displayName, 'Failed');
      expect(PaymentStatus.refunded.displayName, 'Refunded');
    });

    test('firestoreValue returns name', () {
      expect(PaymentStatus.pending.firestoreValue, 'pending');
      expect(PaymentStatus.completed.firestoreValue, 'completed');
    });

    test('fromString parses known values', () {
      expect(PaymentStatus.fromString('pending'), PaymentStatus.pending);
      expect(PaymentStatus.fromString('refunded'), PaymentStatus.refunded);
    });

    test('fromString defaults to pending for unknown values', () {
      expect(PaymentStatus.fromString('xyz'), PaymentStatus.pending);
    });
  });

  group('UserRole', () {
    test('displayName returns human-readable strings', () {
      expect(UserRole.customer.displayName, 'Customer');
      expect(UserRole.deliveryPartner.displayName, 'Delivery Partner');
      expect(UserRole.admin.displayName, 'Admin');
    });

    test('claimValue returns Firestore claim strings', () {
      expect(UserRole.customer.claimValue, 'customer');
      expect(UserRole.deliveryPartner.claimValue, 'deliveryPartner');
      expect(UserRole.admin.claimValue, 'admin');
    });

    test('fromString parses known values', () {
      expect(UserRole.fromString('customer'), UserRole.customer);
      expect(UserRole.fromString('deliveryPartner'), UserRole.deliveryPartner);
      expect(UserRole.fromString('admin'), UserRole.admin);
    });

    test('fromString returns null for unknown or null values', () {
      expect(UserRole.fromString(null), isNull);
      expect(UserRole.fromString('unknown'), isNull);
    });
  });
}
