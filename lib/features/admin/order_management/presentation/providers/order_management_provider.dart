import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/injection_container.dart';

// ---------------------------------------------------------------------------
// Filter state
// ---------------------------------------------------------------------------

class OrderFilter {
  final OrderStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;

  const OrderFilter({this.status, this.startDate, this.endDate});

  OrderFilter copyWith({
    OrderStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool clearStatus = false,
    bool clearDateRange = false,
  }) {
    return OrderFilter(
      status: clearStatus ? null : (status ?? this.status),
      startDate: clearDateRange ? null : (startDate ?? this.startDate),
      endDate: clearDateRange ? null : (endDate ?? this.endDate),
    );
  }
}

class OrderFilterNotifier extends Notifier<OrderFilter> {
  @override
  OrderFilter build() => const OrderFilter();

  void update(OrderFilter value) {
    state = value;
  }
}

final orderFilterProvider =
    NotifierProvider<OrderFilterNotifier, OrderFilter>(
        OrderFilterNotifier.new);

// ---------------------------------------------------------------------------
// All admin orders
// ---------------------------------------------------------------------------

final allAdminOrdersProvider = FutureProvider.autoDispose<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) async {
  final firestore = ref.watch(firestoreProvider);

  final snapshot = await firestore
      .collection(FirebaseConstants.ordersCollection)
      .orderBy('createdAt', descending: true)
      .limit(200)
      .get();

  return snapshot.docs;
});

// ---------------------------------------------------------------------------
// Filtered orders
// ---------------------------------------------------------------------------

final filteredOrdersProvider = Provider.autoDispose<
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>>((ref) {
  final ordersAsync = ref.watch(allAdminOrdersProvider);
  final filter = ref.watch(orderFilterProvider);

  return ordersAsync.whenData((orders) {
    var filtered = orders;

    // Filter by status
    if (filter.status != null) {
      filtered = filtered
          .where((doc) =>
              doc.data()['status'] == filter.status!.firestoreValue)
          .toList();
    }

    // Filter by date range
    if (filter.startDate != null) {
      filtered = filtered.where((doc) {
        final createdAt = doc.data()['createdAt'] as Timestamp?;
        if (createdAt == null) return false;
        return createdAt.toDate().isAfter(filter.startDate!);
      }).toList();
    }

    if (filter.endDate != null) {
      filtered = filtered.where((doc) {
        final createdAt = doc.data()['createdAt'] as Timestamp?;
        if (createdAt == null) return false;
        return createdAt
            .toDate()
            .isBefore(filter.endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
  });
});

// ---------------------------------------------------------------------------
// Dispute orders (cancelled orders with cancellation reason)
// ---------------------------------------------------------------------------

final disputeOrdersProvider = FutureProvider.autoDispose<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) async {
  final firestore = ref.watch(firestoreProvider);

  final snapshot = await firestore
      .collection(FirebaseConstants.ordersCollection)
      .where('hasDispute', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .get();

  return snapshot.docs;
});
