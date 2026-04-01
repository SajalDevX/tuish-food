import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/features/customer/tracking/data/datasources/tracking_remote_datasource.dart';
import 'package:tuish_food/features/customer/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:tuish_food/features/customer/tracking/domain/entities/delivery_location.dart';
import 'package:tuish_food/features/customer/tracking/domain/repositories/tracking_repository.dart';
import 'package:tuish_food/injection_container.dart';

// Data source
final trackingRemoteDataSourceProvider =
    Provider<TrackingRemoteDataSource>((ref) {
  return TrackingRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
  );
});

// Repository
final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  return TrackingRepositoryImpl(
    remoteDataSource: ref.watch(trackingRemoteDataSourceProvider),
  );
});

// Stream delivery location
final deliveryLocationProvider =
    StreamProvider.family<DeliveryLocation, String>((ref, partnerId) {
  final repository = ref.watch(trackingRepositoryProvider);
  return repository.streamDeliveryLocation(partnerId);
});
