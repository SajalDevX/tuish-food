import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/features/delivery/dashboard/data/datasources/delivery_remote_datasource.dart';
import 'package:tuish_food/features/delivery/dashboard/data/repositories/delivery_repository_impl.dart';
import 'package:tuish_food/features/delivery/dashboard/domain/entities/delivery_order.dart';
import 'package:tuish_food/features/delivery/dashboard/domain/repositories/delivery_repository.dart';
import 'package:tuish_food/injection_container.dart';

// ---------------------------------------------------------------------------
// Datasource & Repository providers
// ---------------------------------------------------------------------------

final deliveryRemoteDatasourceProvider =
    Provider<DeliveryRemoteDatasource>((ref) {
  return DeliveryRemoteDatasourceImpl(
    firestore: ref.watch(firestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepositoryImpl(
    remoteDatasource: ref.watch(deliveryRemoteDatasourceProvider),
  );
});

// ---------------------------------------------------------------------------
// Available orders (stream)
// ---------------------------------------------------------------------------

final availableOrdersProvider =
    StreamProvider<List<DeliveryOrder>>((ref) {
  final repository = ref.watch(deliveryRepositoryProvider);
  return repository.getAvailableOrders().map(
        (either) => either.fold(
          (failure) => throw Exception(failure.message),
          (orders) => orders,
        ),
      );
});

// ---------------------------------------------------------------------------
// Active delivery
// ---------------------------------------------------------------------------

final activeDeliveryProvider =
    FutureProvider<DeliveryOrder?>((ref) async {
  final repository = ref.watch(deliveryRepositoryProvider);
  final result = await repository.getActiveDelivery();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (order) => order,
  );
});

// ---------------------------------------------------------------------------
// Delivery history
// ---------------------------------------------------------------------------

final deliveryHistoryProvider =
    FutureProvider<List<DeliveryOrder>>((ref) async {
  final repository = ref.watch(deliveryRepositoryProvider);
  final result = await repository.getDeliveryHistory();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (orders) => orders,
  );
});

// ---------------------------------------------------------------------------
// Accept order
// ---------------------------------------------------------------------------

final acceptOrderProvider =
    FutureProvider.family<DeliveryOrder, String>((ref, orderId) async {
  final repository = ref.watch(deliveryRepositoryProvider);
  final result = await repository.acceptOrder(orderId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (order) => order,
  );
});

// ---------------------------------------------------------------------------
// Update order status
// ---------------------------------------------------------------------------

class UpdateStatusParams {
  final String orderId;
  final OrderStatus status;
  const UpdateStatusParams(this.orderId, this.status);
}

final updateStatusProvider =
    FutureProvider.family<void, UpdateStatusParams>((ref, params) async {
  final repository = ref.watch(deliveryRepositoryProvider);
  final result = await repository.updateOrderStatus(
    params.orderId,
    params.status,
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (_) {},
  );
});

// ---------------------------------------------------------------------------
// Online / Offline toggle state
// ---------------------------------------------------------------------------

final isOnlineProvider = NotifierProvider<OnlineStatusNotifier, bool>(
    OnlineStatusNotifier.new);

class OnlineStatusNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadStatus();
    return false;
  }

  FirebaseFirestore get _firestore => ref.watch(firestoreProvider);
  FirebaseAuth get _auth => ref.watch(firebaseAuthProvider);

  Future<void> _loadStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        state = (doc.data()?['isOnline'] as bool?) ?? false;
      }
    } catch (_) {}
  }

  Future<void> toggle() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final newStatus = !state;
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': newStatus,
        'lastOnlineAt': FieldValue.serverTimestamp(),
      });
      state = newStatus;
    } catch (_) {
      // Revert on failure
    }
  }
}
