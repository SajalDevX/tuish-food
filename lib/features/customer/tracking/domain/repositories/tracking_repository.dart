import 'package:tuish_food/features/customer/tracking/domain/entities/delivery_location.dart';

abstract class TrackingRepository {
  Stream<DeliveryLocation> streamDeliveryLocation(String partnerId);
}
