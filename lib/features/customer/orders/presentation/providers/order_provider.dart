import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/features/customer/orders/data/datasources/order_remote_datasource.dart';
import 'package:tuish_food/features/customer/orders/data/repositories/order_repository_impl.dart';
import 'package:tuish_food/features/customer/orders/domain/entities/order.dart';
import 'package:tuish_food/features/customer/orders/domain/repositories/order_repository.dart';
import 'package:tuish_food/injection_container.dart';

// Data source
final orderRemoteDataSourceProvider =
    Provider<OrderRemoteDataSource>((ref) {
  return OrderRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
  );
});

// Repository
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(
    remoteDataSource: ref.watch(orderRemoteDataSourceProvider),
  );
});

// Customer orders list
final customerOrdersProvider =
    FutureProvider.family<List<CustomerOrder>, String>((ref, userId) async {
  final repository = ref.watch(orderRepositoryProvider);
  final result = await repository.getCustomerOrders(userId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (orders) => orders,
  );
});

// Active orders only
final activeOrdersProvider =
    FutureProvider.family<List<CustomerOrder>, String>((ref, userId) async {
  final repository = ref.watch(orderRepositoryProvider);
  final result = await repository.getCustomerOrders(userId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (orders) => orders.where((o) => o.isActive).toList(),
  );
});

// Past orders only
final pastOrdersProvider =
    FutureProvider.family<List<CustomerOrder>, String>((ref, userId) async {
  final repository = ref.watch(orderRepositoryProvider);
  final result = await repository.getCustomerOrders(userId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (orders) => orders.where((o) => o.isTerminal).toList(),
  );
});

// Single order details
final orderDetailProvider =
    FutureProvider.family<CustomerOrder, String>((ref, orderId) async {
  final repository = ref.watch(orderRepositoryProvider);
  final result = await repository.getOrderDetails(orderId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (order) => order,
  );
});

// Watch order stream
final watchOrderProvider =
    StreamProvider.family<CustomerOrder, String>((ref, orderId) {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.watchOrder(orderId);
});

// Cancel order
final cancelOrderProvider =
    FutureProvider.family<void, ({String orderId, String reason})>(
        (ref, params) async {
  final repository = ref.watch(orderRepositoryProvider);
  final result =
      await repository.cancelOrder(params.orderId, params.reason);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (_) {},
  );
});
