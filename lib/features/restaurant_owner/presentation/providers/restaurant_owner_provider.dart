import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/features/admin/restaurant_management/presentation/providers/restaurant_management_provider.dart';
import 'package:tuish_food/features/customer/home/data/models/restaurant_model.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_item.dart';
import 'package:tuish_food/features/customer/orders/domain/entities/order.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/enums/payment_status.dart';
import 'package:tuish_food/injection_container.dart';

// ---------------------------------------------------------------------------
// My Restaurant (the restaurant owned by the current user)
// ---------------------------------------------------------------------------

final myRestaurantProvider =
    FutureProvider.autoDispose<Restaurant?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final snapshot = await FirebaseFirestore.instance
      .collection('restaurants')
      .where('ownerUid', isEqualTo: user.uid)
      .limit(1)
      .get();

  if (snapshot.docs.isEmpty) return null;

  // Reuse the existing model parser to avoid duplication
  return RestaurantModel.fromFirestore(snapshot.docs.first);
});

/// The restaurant ID for the current owner, or null.
final myRestaurantIdProvider = Provider.autoDispose<String?>((ref) {
  return ref.watch(myRestaurantProvider).value?.id;
});

/// True once [myRestaurantProvider] has resolved AND returned null,
/// meaning this owner has not set up a restaurant yet.
/// Used by the router to auto-redirect first-time owners to setup.
final needsRestaurantSetupProvider = Provider.autoDispose<bool>((ref) {
  final restaurantAsync = ref.watch(myRestaurantProvider);
  return restaurantAsync.hasValue && restaurantAsync.value == null;
});

// ---------------------------------------------------------------------------
// Menu items for the owner's restaurant
// ---------------------------------------------------------------------------

final myMenuItemsProvider =
    FutureProvider.autoDispose<List<MenuItem>>((ref) async {
  final restaurantId = ref.watch(myRestaurantIdProvider);
  if (restaurantId == null) return [];

  final repo = ref.watch(adminRestaurantRepositoryProvider);
  final result = await repo.getMenuItems(restaurantId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (items) => items,
  );
});

// ---------------------------------------------------------------------------
// Orders for the owner's restaurant
// ---------------------------------------------------------------------------

final myRestaurantOrdersProvider =
    FutureProvider.autoDispose<List<CustomerOrder>>((ref) async {
  final restaurantId = ref.watch(myRestaurantIdProvider);
  if (restaurantId == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .get();

  return snapshot.docs.map(_parseOrder).toList();
});

/// Single order detail for the owner.
final myOrderDetailProvider =
    FutureProvider.autoDispose.family<CustomerOrder?, String>((ref, orderId) async {
  final doc = await FirebaseFirestore.instance
      .collection('orders')
      .doc(orderId)
      .get();

  if (!doc.exists) return null;
  return _parseOrder(doc);
});

/// Shared parser for order documents — used by both list and detail providers.
CustomerOrder _parseOrder(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data()!;
  return CustomerOrder(
    id: doc.id,
    orderNumber: data['orderNumber'] as String? ?? '',
    customerId: data['customerId'] as String? ?? '',
    restaurantId: data['restaurantId'] as String? ?? '',
    restaurantName: data['restaurantName'] as String?,
    deliveryPartnerId: data['deliveryPartnerId'] as String?,
    items: ((data['items'] as List<dynamic>?) ?? []).map((item) {
      final m = item as Map<String, dynamic>;
      return OrderItem(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        price: (m['price'] as num?)?.toDouble() ?? 0,
        totalPrice: (m['totalPrice'] as num?)?.toDouble() ?? 0,
      );
    }).toList(),
    subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
    deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0,
    serviceFee: (data['serviceFee'] as num?)?.toDouble() ?? 0,
    tax: (data['tax'] as num?)?.toDouble() ?? 0,
    tip: (data['tip'] as num?)?.toDouble() ?? 0,
    discount: (data['discount'] as num?)?.toDouble() ?? 0,
    totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
    status: OrderStatus.fromString(data['status'] as String? ?? 'placed'),
    paymentMethod: data['paymentMethod'] as String? ?? '',
    paymentStatus: PaymentStatus.fromString(
        data['paymentStatus'] as String? ?? 'pending'),
    deliveryAddress: data['deliveryAddress'] as String?,
    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

// ---------------------------------------------------------------------------
// Restaurant setup (create)
// ---------------------------------------------------------------------------

Future<String> createRestaurant(
  WidgetRef ref, {
  required Map<String, dynamic> data,
}) async {
  final repo = ref.read(adminRestaurantRepositoryProvider);
  final result = await repo.createRestaurant(data);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (restaurant) {
      ref.invalidate(myRestaurantProvider);
      return restaurant.id;
    },
  );
}

// ---------------------------------------------------------------------------
// Update menu item availability
// ---------------------------------------------------------------------------

Future<void> updateMenuItemAvailability(
  WidgetRef ref, {
  required String restaurantId,
  required String itemId,
  required bool isAvailable,
}) async {
  await FirebaseFirestore.instance
      .collection('restaurants')
      .doc(restaurantId)
      .collection('menuItems')
      .doc(itemId)
      .update({'isAvailable': isAvailable});
  ref.invalidate(myMenuItemsProvider);
}

// ---------------------------------------------------------------------------
// Update order status
// ---------------------------------------------------------------------------

Future<void> updateOrderStatus(
  WidgetRef ref, {
  required String orderId,
  required String newStatus,
}) async {
  await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
    'status': newStatus,
    'updatedAt': FieldValue.serverTimestamp(),
  });
  ref.invalidate(myRestaurantOrdersProvider);
}
