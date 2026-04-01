import 'package:equatable/equatable.dart';

import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/enums/payment_status.dart';

class OrderItem extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final int quantity;
  final double price;
  final double totalPrice;
  final String? specialInstructions;
  final List<String> customizations;

  const OrderItem({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    this.specialInstructions,
    this.customizations = const [],
  });

  @override
  List<Object?> get props => [
        id,
        name,
        imageUrl,
        quantity,
        price,
        totalPrice,
        specialInstructions,
        customizations,
      ];
}

class StatusHistoryEntry extends Equatable {
  final OrderStatus status;
  final DateTime timestamp;
  final String? note;

  const StatusHistoryEntry({
    required this.status,
    required this.timestamp,
    this.note,
  });

  @override
  List<Object?> get props => [status, timestamp, note];
}

class CustomerOrder extends Equatable {
  final String id;
  final String orderNumber;
  final String customerId;
  final String restaurantId;
  final String? restaurantName;
  final String? restaurantImageUrl;
  final String? deliveryPartnerId;
  final String? deliveryPartnerName;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double tax;
  final double tip;
  final double discount;
  final double totalAmount;
  final OrderStatus status;
  final List<StatusHistoryEntry> statusHistory;
  final String paymentMethod;
  final PaymentStatus paymentStatus;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final String? deliveryAddress;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerOrder({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.restaurantId,
    this.restaurantName,
    this.restaurantImageUrl,
    this.deliveryPartnerId,
    this.deliveryPartnerName,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.tax,
    this.tip = 0,
    this.discount = 0,
    required this.totalAmount,
    required this.status,
    this.statusHistory = const [],
    required this.paymentMethod,
    required this.paymentStatus,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    this.deliveryAddress,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status.isActive;
  bool get isTerminal => status.isTerminal;
  int get totalItemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        customerId,
        restaurantId,
        restaurantName,
        restaurantImageUrl,
        deliveryPartnerId,
        deliveryPartnerName,
        items,
        subtotal,
        deliveryFee,
        serviceFee,
        tax,
        tip,
        discount,
        totalAmount,
        status,
        statusHistory,
        paymentMethod,
        paymentStatus,
        estimatedDeliveryTime,
        actualDeliveryTime,
        deliveryAddress,
        cancellationReason,
        createdAt,
        updatedAt,
      ];
}
