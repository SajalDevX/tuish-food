import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/features/delivery/dashboard/domain/entities/delivery_order.dart';

class DeliveryOrderModel extends DeliveryOrder {
  const DeliveryOrderModel({
    required super.orderId,
    required super.orderNumber,
    required super.restaurantName,
    required super.restaurantAddress,
    required super.restaurantLat,
    required super.restaurantLng,
    required super.customerName,
    required super.customerAddress,
    required super.customerLat,
    required super.customerLng,
    required super.itemsCount,
    required super.totalAmount,
    required super.deliveryFee,
    required super.status,
    super.estimatedPickupTime,
    required super.distanceKm,
    required super.createdAt,
    super.deliveryPartnerId,
  });

  factory DeliveryOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    final restaurantLocation = data['restaurantLocation'] as Map<String, dynamic>?;
    final customerLocation = data['customerLocation'] as Map<String, dynamic>?;

    return DeliveryOrderModel(
      orderId: doc.id,
      orderNumber: data['orderNumber'] as String? ?? '',
      restaurantName: data['restaurantName'] as String? ?? '',
      restaurantAddress: data['restaurantAddress'] as String? ?? '',
      restaurantLat: (restaurantLocation?['lat'] as num?)?.toDouble() ?? 0.0,
      restaurantLng: (restaurantLocation?['lng'] as num?)?.toDouble() ?? 0.0,
      customerName: data['customerName'] as String? ?? '',
      customerAddress: data['customerAddress'] as String? ?? '',
      customerLat: (customerLocation?['lat'] as num?)?.toDouble() ?? 0.0,
      customerLng: (customerLocation?['lng'] as num?)?.toDouble() ?? 0.0,
      itemsCount: (data['itemsCount'] as num?)?.toInt() ?? 0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.fromString(data['status'] as String? ?? 'placed'),
      estimatedPickupTime: data['estimatedPickupTime'] != null
          ? (data['estimatedPickupTime'] as Timestamp).toDate()
          : null,
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0.0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      deliveryPartnerId: data['deliveryPartnerId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'restaurantName': restaurantName,
      'restaurantAddress': restaurantAddress,
      'restaurantLocation': {
        'lat': restaurantLat,
        'lng': restaurantLng,
      },
      'customerName': customerName,
      'customerAddress': customerAddress,
      'customerLocation': {
        'lat': customerLat,
        'lng': customerLng,
      },
      'itemsCount': itemsCount,
      'totalAmount': totalAmount,
      'deliveryFee': deliveryFee,
      'status': status.firestoreValue,
      if (estimatedPickupTime != null)
        'estimatedPickupTime': Timestamp.fromDate(estimatedPickupTime!),
      'distanceKm': distanceKm,
      'createdAt': Timestamp.fromDate(createdAt),
      if (deliveryPartnerId != null) 'deliveryPartnerId': deliveryPartnerId,
    };
  }

  factory DeliveryOrderModel.fromEntity(DeliveryOrder entity) {
    return DeliveryOrderModel(
      orderId: entity.orderId,
      orderNumber: entity.orderNumber,
      restaurantName: entity.restaurantName,
      restaurantAddress: entity.restaurantAddress,
      restaurantLat: entity.restaurantLat,
      restaurantLng: entity.restaurantLng,
      customerName: entity.customerName,
      customerAddress: entity.customerAddress,
      customerLat: entity.customerLat,
      customerLng: entity.customerLng,
      itemsCount: entity.itemsCount,
      totalAmount: entity.totalAmount,
      deliveryFee: entity.deliveryFee,
      status: entity.status,
      estimatedPickupTime: entity.estimatedPickupTime,
      distanceKm: entity.distanceKm,
      createdAt: entity.createdAt,
      deliveryPartnerId: entity.deliveryPartnerId,
    );
  }
}
