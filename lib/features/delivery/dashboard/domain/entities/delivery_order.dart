import 'package:equatable/equatable.dart';
import 'package:tuish_food/core/enums/order_status.dart';

class DeliveryOrder extends Equatable {
  final String orderId;
  final String orderNumber;
  final String restaurantName;
  final String restaurantAddress;
  final double restaurantLat;
  final double restaurantLng;
  final String customerName;
  final String customerAddress;
  final double customerLat;
  final double customerLng;
  final int itemsCount;
  final double totalAmount;
  final double deliveryFee;
  final OrderStatus status;
  final DateTime? estimatedPickupTime;
  final double distanceKm;
  final DateTime createdAt;
  final String? deliveryPartnerId;

  const DeliveryOrder({
    required this.orderId,
    required this.orderNumber,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.restaurantLat,
    required this.restaurantLng,
    required this.customerName,
    required this.customerAddress,
    required this.customerLat,
    required this.customerLng,
    required this.itemsCount,
    required this.totalAmount,
    required this.deliveryFee,
    required this.status,
    this.estimatedPickupTime,
    required this.distanceKm,
    required this.createdAt,
    this.deliveryPartnerId,
  });

  DeliveryOrder copyWith({
    String? orderId,
    String? orderNumber,
    String? restaurantName,
    String? restaurantAddress,
    double? restaurantLat,
    double? restaurantLng,
    String? customerName,
    String? customerAddress,
    double? customerLat,
    double? customerLng,
    int? itemsCount,
    double? totalAmount,
    double? deliveryFee,
    OrderStatus? status,
    DateTime? estimatedPickupTime,
    double? distanceKm,
    DateTime? createdAt,
    String? deliveryPartnerId,
  }) {
    return DeliveryOrder(
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
      restaurantLat: restaurantLat ?? this.restaurantLat,
      restaurantLng: restaurantLng ?? this.restaurantLng,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      customerLat: customerLat ?? this.customerLat,
      customerLng: customerLng ?? this.customerLng,
      itemsCount: itemsCount ?? this.itemsCount,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      status: status ?? this.status,
      estimatedPickupTime: estimatedPickupTime ?? this.estimatedPickupTime,
      distanceKm: distanceKm ?? this.distanceKm,
      createdAt: createdAt ?? this.createdAt,
      deliveryPartnerId: deliveryPartnerId ?? this.deliveryPartnerId,
    );
  }

  @override
  List<Object?> get props => [
        orderId,
        orderNumber,
        restaurantName,
        restaurantAddress,
        restaurantLat,
        restaurantLng,
        customerName,
        customerAddress,
        customerLat,
        customerLng,
        itemsCount,
        totalAmount,
        deliveryFee,
        status,
        estimatedPickupTime,
        distanceKm,
        createdAt,
        deliveryPartnerId,
      ];
}
