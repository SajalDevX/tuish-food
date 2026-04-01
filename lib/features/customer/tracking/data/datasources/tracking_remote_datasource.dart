import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/features/customer/tracking/domain/entities/delivery_location.dart';

abstract class TrackingRemoteDataSource {
  Stream<DeliveryLocation> streamDeliveryLocation(String partnerId);
}

class TrackingRemoteDataSourceImpl implements TrackingRemoteDataSource {
  final FirebaseFirestore _firestore;

  const TrackingRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Stream<DeliveryLocation> streamDeliveryLocation(String partnerId) {
    return _firestore
        .collection(FirebaseConstants.deliveryLocationsCollection)
        .doc(partnerId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        throw const ServerException('Delivery location not found');
      }

      final data = doc.data()!;
      final geoPoint = data['location'] as GeoPoint?;

      return DeliveryLocation(
        partnerId: data['partnerId'] as String? ?? partnerId,
        latitude: geoPoint?.latitude ?? 0,
        longitude: geoPoint?.longitude ?? 0,
        heading: (data['heading'] as num?)?.toDouble() ?? 0,
        speed: (data['speed'] as num?)?.toDouble() ?? 0,
        updatedAt:
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    });
  }
}
