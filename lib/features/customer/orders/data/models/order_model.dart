import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/enums/payment_status.dart';
import 'package:tuish_food/features/customer/orders/domain/entities/order.dart';

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.id,
    required super.name,
    super.imageUrl,
    required super.quantity,
    required super.price,
    required super.totalPrice,
    super.specialInstructions,
    super.customizations,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id'] as String? ?? map['menuItemId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0,
      specialInstructions: map['specialInstructions'] as String?,
      customizations: (map['customizations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'price': price,
      'totalPrice': totalPrice,
      'specialInstructions': specialInstructions,
      'customizations': customizations,
    };
  }
}

class StatusHistoryEntryModel extends StatusHistoryEntry {
  const StatusHistoryEntryModel({
    required super.status,
    required super.timestamp,
    super.note,
  });

  factory StatusHistoryEntryModel.fromMap(Map<String, dynamic> map) {
    return StatusHistoryEntryModel(
      status: OrderStatus.fromString(map['status'] as String? ?? 'placed'),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.firestoreValue,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
    };
  }
}

class OrderModel extends CustomerOrder {
  const OrderModel({
    required super.id,
    required super.orderNumber,
    required super.customerId,
    required super.restaurantId,
    super.restaurantName,
    super.restaurantImageUrl,
    super.deliveryPartnerId,
    super.deliveryPartnerName,
    required super.items,
    required super.subtotal,
    required super.deliveryFee,
    required super.serviceFee,
    required super.tax,
    super.tip,
    super.discount,
    required super.totalAmount,
    required super.status,
    super.statusHistory,
    required super.paymentMethod,
    required super.paymentStatus,
    super.estimatedDeliveryTime,
    super.actualDeliveryTime,
    super.deliveryAddress,
    super.cancellationReason,
    required super.createdAt,
    required super.updatedAt,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return OrderModel(
      id: doc.id,
      orderNumber: data['orderNumber'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      restaurantId: data['restaurantId'] as String? ?? '',
      restaurantName: data['restaurantName'] as String?,
      restaurantImageUrl: data['restaurantImageUrl'] as String?,
      deliveryPartnerId: data['deliveryPartnerId'] as String?,
      deliveryPartnerName: data['deliveryPartnerName'] as String?,
      items: (data['items'] as List<dynamic>?)
              ?.map((e) =>
                  OrderItemModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0,
      serviceFee: (data['serviceFee'] as num?)?.toDouble() ?? 0,
      tax: (data['tax'] as num?)?.toDouble() ?? 0,
      tip: (data['tip'] as num?)?.toDouble() ?? 0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      status: OrderStatus.fromString(data['status'] as String? ?? 'placed'),
      statusHistory: (data['statusHistory'] as List<dynamic>?)
              ?.map((e) =>
                  StatusHistoryEntryModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
      paymentMethod: data['paymentMethod'] as String? ?? '',
      paymentStatus: PaymentStatus.fromString(
          data['paymentStatus'] as String? ?? 'pending'),
      estimatedDeliveryTime:
          (data['estimatedDeliveryTime'] as Timestamp?)?.toDate(),
      actualDeliveryTime:
          (data['actualDeliveryTime'] as Timestamp?)?.toDate(),
      deliveryAddress: data['deliveryAddress'] as String?,
      cancellationReason: data['cancellationReason'] as String?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderNumber': orderNumber,
      'customerId': customerId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantImageUrl': restaurantImageUrl,
      'deliveryPartnerId': deliveryPartnerId,
      'deliveryPartnerName': deliveryPartnerName,
      'items': items
          .map((e) => (e is OrderItemModel)
              ? e.toMap()
              : OrderItemModel(
                  id: e.id,
                  name: e.name,
                  imageUrl: e.imageUrl,
                  quantity: e.quantity,
                  price: e.price,
                  totalPrice: e.totalPrice,
                  specialInstructions: e.specialInstructions,
                  customizations: e.customizations,
                ).toMap())
          .toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'serviceFee': serviceFee,
      'tax': tax,
      'tip': tip,
      'discount': discount,
      'totalAmount': totalAmount,
      'status': status.firestoreValue,
      'statusHistory': statusHistory
          .map((e) => (e is StatusHistoryEntryModel)
              ? e.toMap()
              : StatusHistoryEntryModel(
                  status: e.status,
                  timestamp: e.timestamp,
                  note: e.note,
                ).toMap())
          .toList(),
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus.firestoreValue,
      'estimatedDeliveryTime': estimatedDeliveryTime != null
          ? Timestamp.fromDate(estimatedDeliveryTime!)
          : null,
      'actualDeliveryTime': actualDeliveryTime != null
          ? Timestamp.fromDate(actualDeliveryTime!)
          : null,
      'deliveryAddress': deliveryAddress,
      'cancellationReason': cancellationReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
