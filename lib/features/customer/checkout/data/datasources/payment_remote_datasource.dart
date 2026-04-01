import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/enums/payment_status.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/features/customer/checkout/data/models/payment_model.dart';
import 'package:tuish_food/features/customer/checkout/domain/entities/payment.dart';
import 'package:tuish_food/features/customer/checkout/domain/repositories/checkout_repository.dart';

abstract class PaymentRemoteDatasource {
  Future<String> placeOrder(PlaceOrderParams params);
  Future<CouponResult> applyCoupon({
    required String code,
    required double subtotal,
  });
  Future<PaymentModel> processPayment({
    required String orderId,
    required PaymentMethod method,
    required double amount,
  });
}

class PaymentRemoteDatasourceImpl implements PaymentRemoteDatasource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const PaymentRemoteDatasourceImpl({
    required this.firestore,
    required this.auth,
  });

  @override
  Future<String> placeOrder(PlaceOrderParams params) async {
    try {
      final user = auth.currentUser;
      if (user == null) throw const AuthException('User not authenticated');

      final orderRef = firestore
          .collection(FirebaseConstants.ordersCollection)
          .doc();

      final orderData = {
        'id': orderRef.id,
        'customerId': user.uid,
        'customerName': user.displayName ?? '',
        'restaurantId': params.restaurantId,
        'restaurantName': params.restaurantName,
        'items': params.items
            .map(
              (item) => {
                'menuItemId': item.menuItemId,
                'name': item.name,
                'price': item.price,
                'quantity': item.quantity,
                'selectedCustomizations': item.selectedCustomizations,
              },
            )
            .toList(),
        'deliveryAddressId': params.deliveryAddressId,
        'deliveryAddress': params.deliveryAddress,
        'paymentMethod': params.paymentMethod.firestoreValue,
        'paymentStatus': PaymentStatus.pending.firestoreValue,
        'status': OrderStatus.placed.firestoreValue,
        'subtotal': params.subtotal,
        'deliveryFee': params.deliveryFee,
        'taxes': params.taxes,
        'tip': params.tip,
        'discount': params.discount,
        'total': params.total,
        'couponCode': params.couponCode,
        'specialInstructions': params.specialInstructions,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await orderRef.set(orderData);
      return orderRef.id;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to place order: $e');
    }
  }

  @override
  Future<CouponResult> applyCoupon({
    required String code,
    required double subtotal,
  }) async {
    try {
      // Query promotions collection for the coupon code
      final snapshot = await firestore
          .collection(FirebaseConstants.promotionsCollection)
          .where('code', isEqualTo: code.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw const ServerException('Invalid coupon code');
      }

      final promoData = snapshot.docs.first.data();
      final discountPercent =
          (promoData['discountPercent'] as num?)?.toDouble() ?? 10.0;
      final maxDiscount =
          (promoData['maxDiscount'] as num?)?.toDouble() ?? 100.0;
      final minOrder = (promoData['minOrderAmount'] as num?)?.toDouble() ?? 0.0;

      if (subtotal < minOrder) {
        throw ServerException(
          'Minimum order amount is \u20B9${minOrder.toStringAsFixed(0)}',
        );
      }

      final discount = (subtotal * discountPercent / 100).clamp(0.0, maxDiscount).toDouble();

      return CouponResult(
        code: code.toUpperCase(),
        discountAmount: discount,
        description:
            '${discountPercent.toStringAsFixed(0)}% off (up to \u20B9${maxDiscount.toStringAsFixed(0)})',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to apply coupon: $e');
    }
  }

  @override
  Future<PaymentModel> processPayment({
    required String orderId,
    required PaymentMethod method,
    required double amount,
  }) async {
    try {
      // For cash on delivery, just mark payment as pending
      if (method == PaymentMethod.cashOnDelivery) {
        await firestore
            .collection(FirebaseConstants.ordersCollection)
            .doc(orderId)
            .update({
              'paymentStatus': PaymentStatus.pending.firestoreValue,
              'paymentMethod': method.firestoreValue,
            });

        return PaymentModel(
          id: orderId,
          method: method,
          status: PaymentStatus.pending,
          amount: amount,
        );
      }

      // For card payment, in production this would call a Cloud Function
      // that integrates with Stripe. For now, simulate success.
      await firestore
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId)
          .update({
            'paymentStatus': PaymentStatus.completed.firestoreValue,
            'paymentMethod': method.firestoreValue,
          });

      return PaymentModel(
        id: orderId,
        method: method,
        status: PaymentStatus.completed,
        amount: amount,
        transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      throw ServerException('Payment processing failed: $e');
    }
  }
}
