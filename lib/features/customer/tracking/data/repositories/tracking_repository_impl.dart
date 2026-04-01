import 'package:tuish_food/features/customer/tracking/data/datasources/tracking_remote_datasource.dart';
import 'package:tuish_food/features/customer/tracking/domain/entities/delivery_location.dart';
import 'package:tuish_food/features/customer/tracking/domain/repositories/tracking_repository.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  final TrackingRemoteDataSource _remoteDataSource;

  const TrackingRepositoryImpl(
      {required TrackingRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Stream<DeliveryLocation> streamDeliveryLocation(String partnerId) {
    return _remoteDataSource.streamDeliveryLocation(partnerId);
  }
}
