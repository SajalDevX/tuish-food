import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tuish_food/features/customer/profile/domain/entities/address.dart';

class AddressModel extends Address {
  const AddressModel({
    required super.id,
    required super.label,
    super.customLabel,
    required super.addressLine1,
    super.addressLine2,
    required super.city,
    required super.state,
    required super.zipCode,
    super.latitude,
    super.longitude,
    super.isDefault,
  });

  factory AddressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final location = data['location'] as GeoPoint?;

    return AddressModel(
      id: doc.id,
      label: data['label'] as String? ?? 'Home',
      customLabel: data['customLabel'] as String?,
      addressLine1: data['addressLine1'] as String? ?? '',
      addressLine2: data['addressLine2'] as String?,
      city: data['city'] as String? ?? '',
      state: data['state'] as String? ?? '',
      zipCode: data['zipCode'] as String? ?? '',
      latitude: location?.latitude,
      longitude: location?.longitude,
      isDefault: data['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'label': label,
      'customLabel': customLabel,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'location': latitude != null && longitude != null
          ? GeoPoint(latitude!, longitude!)
          : null,
      'isDefault': isDefault,
    };
  }

  factory AddressModel.fromEntity(Address address) {
    return AddressModel(
      id: address.id,
      label: address.label,
      customLabel: address.customLabel,
      addressLine1: address.addressLine1,
      addressLine2: address.addressLine2,
      city: address.city,
      state: address.state,
      zipCode: address.zipCode,
      latitude: address.latitude,
      longitude: address.longitude,
      isDefault: address.isDefault,
    );
  }
}
