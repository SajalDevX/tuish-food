enum OrderStatus {
  placed,
  confirmed,
  preparing,
  readyForPickup,
  pickedUp,
  onTheWay,
  delivered,
  cancelled;

  String get displayName {
    return switch (this) {
      OrderStatus.placed => 'Order Placed',
      OrderStatus.confirmed => 'Confirmed',
      OrderStatus.preparing => 'Preparing',
      OrderStatus.readyForPickup => 'Ready for Pickup',
      OrderStatus.pickedUp => 'Picked Up',
      OrderStatus.onTheWay => 'On the Way',
      OrderStatus.delivered => 'Delivered',
      OrderStatus.cancelled => 'Cancelled',
    };
  }

  String get firestoreValue {
    return switch (this) {
      OrderStatus.placed => 'placed',
      OrderStatus.confirmed => 'confirmed',
      OrderStatus.preparing => 'preparing',
      OrderStatus.readyForPickup => 'readyForPickup',
      OrderStatus.pickedUp => 'pickedUp',
      OrderStatus.onTheWay => 'onTheWay',
      OrderStatus.delivered => 'delivered',
      OrderStatus.cancelled => 'cancelled',
    };
  }

  bool get isActive =>
      this != OrderStatus.delivered && this != OrderStatus.cancelled;

  bool get isTerminal =>
      this == OrderStatus.delivered || this == OrderStatus.cancelled;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.firestoreValue == value,
      orElse: () => OrderStatus.placed,
    );
  }
}
