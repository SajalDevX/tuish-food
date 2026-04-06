import 'package:equatable/equatable.dart';

class RestaurantAddress extends Equatable {
  final String addressLine1;
  final String city;
  final String state;
  final double latitude;
  final double longitude;

  const RestaurantAddress({
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
  });

  String get fullAddress => '$addressLine1, $city, $state';

  @override
  List<Object?> get props => [addressLine1, city, state, latitude, longitude];
}

class OperatingHours extends Equatable {
  final String day;
  final String openTime;
  final String closeTime;
  final bool isClosed;

  const OperatingHours({
    required this.day,
    required this.openTime,
    required this.closeTime,
    this.isClosed = false,
  });

  @override
  List<Object?> get props => [day, openTime, closeTime, isClosed];
}

class Restaurant extends Equatable {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String coverImageUrl;
  final List<String> cuisineTypes;
  final List<String> tags;
  final int priceLevel;
  final bool isActive;
  final bool isOpen;
  final int preparationTimeMinutes;
  final double minimumOrderAmount;
  final double deliveryFee;
  final double freeDeliveryAbove;
  final double averageRating;
  final int totalRatings;
  final int totalOrders;
  final String? ownerUid;
  final RestaurantAddress address;
  final List<OperatingHours> operatingHours;

  // Subscription fields
  final String? subscriptionStatus;
  final String? subscriptionId;
  final DateTime? subscriptionCurrentEnd;
  final DateTime? subscriptionGraceDeadline;
  final bool isSubscriptionValid;

  const Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.coverImageUrl,
    required this.cuisineTypes,
    required this.tags,
    required this.priceLevel,
    required this.isActive,
    required this.isOpen,
    required this.preparationTimeMinutes,
    required this.minimumOrderAmount,
    required this.deliveryFee,
    required this.freeDeliveryAbove,
    required this.averageRating,
    required this.totalRatings,
    required this.totalOrders,
    this.ownerUid,
    required this.address,
    required this.operatingHours,
    this.subscriptionStatus,
    this.subscriptionId,
    this.subscriptionCurrentEnd,
    this.subscriptionGraceDeadline,
    this.isSubscriptionValid = true,
  });

  String get priceLevelLabel => '\$' * priceLevel;

  String get cuisineTypesLabel => cuisineTypes.join(', ');

  String get deliveryTimeLabel => '$preparationTimeMinutes min';

  String get deliveryFeeLabel =>
      deliveryFee == 0 ? 'Free delivery' : '\$${deliveryFee.toStringAsFixed(2)}';

  Restaurant copyWith({
    String? subscriptionStatus,
    String? subscriptionId,
    DateTime? subscriptionCurrentEnd,
    DateTime? subscriptionGraceDeadline,
    bool? isSubscriptionValid,
  }) {
    return Restaurant(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      coverImageUrl: coverImageUrl,
      cuisineTypes: cuisineTypes,
      tags: tags,
      priceLevel: priceLevel,
      isActive: isActive,
      isOpen: isOpen,
      preparationTimeMinutes: preparationTimeMinutes,
      minimumOrderAmount: minimumOrderAmount,
      deliveryFee: deliveryFee,
      freeDeliveryAbove: freeDeliveryAbove,
      averageRating: averageRating,
      totalRatings: totalRatings,
      totalOrders: totalOrders,
      ownerUid: ownerUid,
      address: address,
      operatingHours: operatingHours,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      subscriptionCurrentEnd: subscriptionCurrentEnd ?? this.subscriptionCurrentEnd,
      subscriptionGraceDeadline: subscriptionGraceDeadline ?? this.subscriptionGraceDeadline,
      isSubscriptionValid: isSubscriptionValid ?? this.isSubscriptionValid,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        imageUrl,
        coverImageUrl,
        cuisineTypes,
        tags,
        priceLevel,
        isActive,
        isOpen,
        preparationTimeMinutes,
        minimumOrderAmount,
        deliveryFee,
        freeDeliveryAbove,
        averageRating,
        totalRatings,
        totalOrders,
        ownerUid,
        address,
        operatingHours,
        subscriptionStatus,
        subscriptionId,
        subscriptionCurrentEnd,
        subscriptionGraceDeadline,
        isSubscriptionValid,
      ];
}
