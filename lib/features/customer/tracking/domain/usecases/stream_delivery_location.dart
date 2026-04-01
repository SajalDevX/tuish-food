import 'package:tuish_food/features/customer/tracking/domain/entities/delivery_location.dart';
import 'package:tuish_food/features/customer/tracking/domain/repositories/tracking_repository.dart';

class StreamDeliveryLocation {
  final TrackingRepository repository;

  const StreamDeliveryLocation(this.repository);

  Stream<DeliveryLocation> call(String partnerId) {
    return repository.streamDeliveryLocation(partnerId);
  }
}
