import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/features/delivery/dashboard/data/models/delivery_order_model.dart';

abstract class DeliveryRemoteDatasource {
  Stream<List<DeliveryOrderModel>> getAvailableOrders();
  Future<DeliveryOrderModel> acceptOrder(String orderId);
  Future<void> rejectOrder(String orderId);
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
  Future<DeliveryOrderModel?> getActiveDelivery();
  Future<List<DeliveryOrderModel>> getDeliveryHistory();
}

class DeliveryRemoteDatasourceImpl implements DeliveryRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  const DeliveryRemoteDatasourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException('User not authenticated');
    return user.uid;
  }

  CollectionReference get _ordersCollection =>
      _firestore.collection(FirebaseConstants.ordersCollection);

  @override
  Stream<List<DeliveryOrderModel>> getAvailableOrders() {
    return _ordersCollection
        .where('status', isEqualTo: OrderStatus.readyForPickup.firestoreValue)
        .where('deliveryPartnerId', isNull: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryOrderModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<DeliveryOrderModel> acceptOrder(String orderId) async {
    try {
      final docRef = _ordersCollection.doc(orderId);

      return await _firestore.runTransaction<DeliveryOrderModel>((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) {
          throw const ServerException('Order not found');
        }

        final data = doc.data()! as Map<String, dynamic>;
        if (data['deliveryPartnerId'] != null) {
          throw const ServerException('Order already accepted by another partner');
        }

        transaction.update(docRef, {
          'deliveryPartnerId': _currentUserId,
          'status': OrderStatus.pickedUp.firestoreValue,
          'acceptedAt': FieldValue.serverTimestamp(),
        });

        // Return updated model
        final updatedDoc = await docRef.get();
        return DeliveryOrderModel.fromFirestore(updatedDoc);
      });
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to accept order: $e');
    }
  }

  @override
  Future<void> rejectOrder(String orderId) async {
    try {
      final userId = _currentUserId;
      await _ordersCollection.doc(orderId).update({
        'rejectedBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw ServerException('Failed to reject order: $e');
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final updates = <String, dynamic>{
        'status': status.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == OrderStatus.delivered) {
        updates['deliveredAt'] = FieldValue.serverTimestamp();
      }

      await _ordersCollection.doc(orderId).update(updates);
    } catch (e) {
      throw ServerException('Failed to update order status: $e');
    }
  }

  @override
  Future<DeliveryOrderModel?> getActiveDelivery() async {
    try {
      final userId = _currentUserId;
      final snapshot = await _ordersCollection
          .where('deliveryPartnerId', isEqualTo: userId)
          .where('status', whereIn: [
            OrderStatus.pickedUp.firestoreValue,
            OrderStatus.onTheWay.firestoreValue,
          ])
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return DeliveryOrderModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      throw ServerException('Failed to get active delivery: $e');
    }
  }

  @override
  Future<List<DeliveryOrderModel>> getDeliveryHistory() async {
    try {
      final userId = _currentUserId;
      final snapshot = await _ordersCollection
          .where('deliveryPartnerId', isEqualTo: userId)
          .where('status', isEqualTo: OrderStatus.delivered.firestoreValue)
          .orderBy('deliveredAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => DeliveryOrderModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get delivery history: $e');
    }
  }
}
