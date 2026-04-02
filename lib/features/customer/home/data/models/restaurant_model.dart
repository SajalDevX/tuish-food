import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';

class RestaurantModel extends Restaurant {
  const RestaurantModel({
    required super.id,
    required super.name,
    required super.description,
    required super.imageUrl,
    required super.coverImageUrl,
    required super.cuisineTypes,
    required super.tags,
    required super.priceLevel,
    required super.isActive,
    required super.isOpen,
    super.ownerUid,
    required super.preparationTimeMinutes,
    required super.minimumOrderAmount,
    required super.deliveryFee,
    required super.freeDeliveryAbove,
    required super.averageRating,
    required super.totalRatings,
    required super.totalOrders,
    required super.address,
    required super.operatingHours,
  });

  factory RestaurantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Parse address
    final addressData = data['address'] as Map<String, dynamic>? ?? {};
    final geoPoint = addressData['location'] as GeoPoint?;

    final address = RestaurantAddress(
      addressLine1: addressData['addressLine1'] as String? ?? '',
      city: addressData['city'] as String? ?? '',
      state: addressData['state'] as String? ?? '',
      latitude: geoPoint?.latitude ?? 0.0,
      longitude: geoPoint?.longitude ?? 0.0,
    );

    // Parse operating hours
    final hoursData = data['operatingHours'] as List<dynamic>? ?? [];
    final operatingHours = hoursData.map((item) {
      final hourMap = item as Map<String, dynamic>;
      return OperatingHours(
        day: hourMap['day'] as String? ?? '',
        openTime: hourMap['openTime'] as String? ?? '',
        closeTime: hourMap['closeTime'] as String? ?? '',
        isClosed: hourMap['isClosed'] as bool? ?? false,
      );
    }).toList();

    return RestaurantModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      coverImageUrl: data['coverImageUrl'] as String? ?? '',
      cuisineTypes: List<String>.from(data['cuisineTypes'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      priceLevel: data['priceLevel'] as int? ?? 1,
      isActive: data['isActive'] as bool? ?? false,
      isOpen: data['isOpen'] as bool? ?? false,
      ownerUid: data['ownerUid'] as String?,
      preparationTimeMinutes: data['preparationTimeMinutes'] as int? ?? 30,
      minimumOrderAmount: (data['minimumOrderAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      freeDeliveryAbove: (data['freeDeliveryAbove'] as num?)?.toDouble() ?? 0.0,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: data['totalRatings'] as int? ?? 0,
      totalOrders: data['totalOrders'] as int? ?? 0,
      address: address,
      operatingHours: operatingHours,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'coverImageUrl': coverImageUrl,
      'cuisineTypes': cuisineTypes,
      'tags': tags,
      'priceLevel': priceLevel,
      'isActive': isActive,
      'isOpen': isOpen,
      if (ownerUid != null) 'ownerUid': ownerUid,
      'preparationTimeMinutes': preparationTimeMinutes,
      'minimumOrderAmount': minimumOrderAmount,
      'deliveryFee': deliveryFee,
      'freeDeliveryAbove': freeDeliveryAbove,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'totalOrders': totalOrders,
      'address': {
        'addressLine1': address.addressLine1,
        'city': address.city,
        'state': address.state,
        'location': GeoPoint(address.latitude, address.longitude),
      },
      'operatingHours': operatingHours
          .map((h) => {
                'day': h.day,
                'openTime': h.openTime,
                'closeTime': h.closeTime,
                'isClosed': h.isClosed,
              })
          .toList(),
    };
  }

  factory RestaurantModel.fromEntity(Restaurant restaurant) {
    return RestaurantModel(
      id: restaurant.id,
      name: restaurant.name,
      description: restaurant.description,
      imageUrl: restaurant.imageUrl,
      coverImageUrl: restaurant.coverImageUrl,
      cuisineTypes: restaurant.cuisineTypes,
      tags: restaurant.tags,
      priceLevel: restaurant.priceLevel,
      isActive: restaurant.isActive,
      isOpen: restaurant.isOpen,
      ownerUid: restaurant.ownerUid,
      preparationTimeMinutes: restaurant.preparationTimeMinutes,
      minimumOrderAmount: restaurant.minimumOrderAmount,
      deliveryFee: restaurant.deliveryFee,
      freeDeliveryAbove: restaurant.freeDeliveryAbove,
      averageRating: restaurant.averageRating,
      totalRatings: restaurant.totalRatings,
      totalOrders: restaurant.totalOrders,
      address: restaurant.address,
      operatingHours: restaurant.operatingHours,
    );
  }
}
