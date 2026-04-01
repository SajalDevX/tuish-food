import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/features/customer/orders/data/models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<List<OrderModel>> getCustomerOrders(String userId);
  Future<OrderModel> getOrderDetails(String orderId);
  Future<void> cancelOrder(String orderId, String reason);
  Stream<OrderModel> watchOrder(String orderId);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final FirebaseFirestore _firestore;

  const OrderRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference get _ordersRef =>
      _firestore.collection(FirebaseConstants.ordersCollection);

  @override
  Future<List<OrderModel>> getCustomerOrders(String userId) async {
    try {
      final snapshot = await _ordersRef
          .where('customerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to fetch orders');
    }
  }

  @override
  Future<OrderModel> getOrderDetails(String orderId) async {
    try {
      final doc = await _ordersRef.doc(orderId).get();
      if (!doc.exists) {
        throw const ServerException('Order not found');
      }
      return OrderModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to fetch order details');
    }
  }

  @override
  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      final now = DateTime.now();
      await _ordersRef.doc(orderId).update({
        'status': OrderStatus.cancelled.firestoreValue,
        'cancellationReason': reason,
        'updatedAt': Timestamp.fromDate(now),
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': OrderStatus.cancelled.firestoreValue,
            'timestamp': Timestamp.fromDate(now),
            'note': reason,
          }
        ]),
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to cancel order');
    }
  }

  @override
  Stream<OrderModel> watchOrder(String orderId) {
    return _ordersRef.doc(orderId).snapshots().map((doc) {
      if (!doc.exists) {
        throw const ServerException('Order not found');
      }
      return OrderModel.fromFirestore(doc);
    });
  }
}
