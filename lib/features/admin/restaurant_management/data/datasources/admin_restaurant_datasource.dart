import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_item.dart';

abstract class AdminRestaurantDatasource {
  Future<List<Restaurant>> getAllRestaurants();
  Future<Restaurant> createRestaurant(Map<String, dynamic> data);
  Future<Restaurant> updateRestaurant(
      String restaurantId, Map<String, dynamic> data);
  Future<void> deleteRestaurant(String restaurantId);
  Future<void> toggleRestaurantStatus(String restaurantId, bool isActive);
  Future<List<MenuItem>> getMenuItems(String restaurantId);
  Future<MenuItem> addMenuItem(
      String restaurantId, Map<String, dynamic> data);
  Future<MenuItem> updateMenuItem(
      String restaurantId, String menuItemId, Map<String, dynamic> data);
  Future<void> deleteMenuItem(String restaurantId, String menuItemId);
}

class AdminRestaurantDatasourceImpl implements AdminRestaurantDatasource {
  final FirebaseFirestore _firestore;

  const AdminRestaurantDatasourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _restaurantsRef =>
      _firestore.collection(FirebaseConstants.restaurantsCollection);

  Restaurant _restaurantFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Restaurant(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      coverImageUrl: data['coverImageUrl'] as String? ?? '',
      cuisineTypes: List<String>.from(data['cuisineTypes'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      priceLevel: (data['priceLevel'] as num?)?.toInt() ?? 1,
      isActive: data['isActive'] as bool? ?? true,
      isOpen: data['isOpen'] as bool? ?? false,
      ownerUid: data['ownerUid'] as String?,
      preparationTimeMinutes:
          (data['preparationTimeMinutes'] as num?)?.toInt() ?? 30,
      minimumOrderAmount:
          (data['minimumOrderAmount'] as num?)?.toDouble() ?? 0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0,
      freeDeliveryAbove:
          (data['freeDeliveryAbove'] as num?)?.toDouble() ?? 0,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0,
      totalRatings: (data['totalRatings'] as num?)?.toInt() ?? 0,
      totalOrders: (data['totalOrders'] as num?)?.toInt() ?? 0,
      address: RestaurantAddress(
        addressLine1:
            (data['address'] as Map<String, dynamic>?)?['addressLine1']
                    as String? ??
                '',
        city: (data['address'] as Map<String, dynamic>?)?['city']
                as String? ??
            '',
        state: (data['address'] as Map<String, dynamic>?)?['state']
                as String? ??
            '',
        latitude: ((data['address']
                    as Map<String, dynamic>?)?['latitude'] as num?)
                ?.toDouble() ??
            0,
        longitude: ((data['address']
                    as Map<String, dynamic>?)?['longitude'] as num?)
                ?.toDouble() ??
            0,
      ),
      operatingHours: ((data['operatingHours'] as List<dynamic>?) ?? [])
          .map((e) {
        final h = e as Map<String, dynamic>;
        return OperatingHours(
          day: h['day'] as String? ?? '',
          openTime: h['openTime'] as String? ?? '09:00',
          closeTime: h['closeTime'] as String? ?? '22:00',
          isClosed: h['isClosed'] as bool? ?? false,
        );
      }).toList(),
    );
  }

  MenuItem _menuItemFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MenuItem(
      id: doc.id,
      categoryId: data['categoryId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      discountedPrice: (data['discountedPrice'] as num?)?.toDouble(),
      isVegetarian: data['isVegetarian'] as bool? ?? false,
      isVegan: data['isVegan'] as bool? ?? false,
      isGlutenFree: data['isGlutenFree'] as bool? ?? false,
      spiceLevel: (data['spiceLevel'] as num?)?.toInt() ?? 0,
      customizations: ((data['customizations'] as List<dynamic>?) ?? [])
          .map((c) {
        final cm = c as Map<String, dynamic>;
        return MenuItemCustomization(
          id: cm['id'] as String? ?? '',
          title: cm['title'] as String? ?? '',
          required: cm['required'] as bool? ?? false,
          multiSelect: cm['multiSelect'] as bool? ?? false,
          maxSelections: (cm['maxSelections'] as num?)?.toInt() ?? 1,
          options: ((cm['options'] as List<dynamic>?) ?? []).map((o) {
            final om = o as Map<String, dynamic>;
            return MenuItemCustomizationOption(
              id: om['id'] as String? ?? '',
              name: om['name'] as String? ?? '',
              additionalPrice:
                  (om['additionalPrice'] as num?)?.toDouble() ?? 0,
            );
          }).toList(),
        );
      }).toList(),
      isAvailable: data['isAvailable'] as bool? ?? true,
      isPopular: data['isPopular'] as bool? ?? false,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      preparationTimeMinutes:
          (data['preparationTimeMinutes'] as num?)?.toInt() ?? 15,
    );
  }

  @override
  Future<List<Restaurant>> getAllRestaurants() async {
    try {
      final snapshot =
          await _restaurantsRef.orderBy('name').get();
      return snapshot.docs.map(_restaurantFromDoc).toList();
    } catch (e) {
      throw ServerException('Failed to fetch restaurants: $e');
    }
  }

  @override
  Future<Restaurant> createRestaurant(Map<String, dynamic> data) async {
    try {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      data['averageRating'] = 0.0;
      data['totalRatings'] = 0;
      data['totalOrders'] = 0;
      final docRef = await _restaurantsRef.add(data);
      final doc = await docRef.get();
      return _restaurantFromDoc(doc);
    } catch (e) {
      throw ServerException('Failed to create restaurant: $e');
    }
  }

  @override
  Future<Restaurant> updateRestaurant(
    String restaurantId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _restaurantsRef.doc(restaurantId).update(data);
      final doc = await _restaurantsRef.doc(restaurantId).get();
      return _restaurantFromDoc(doc);
    } catch (e) {
      throw ServerException('Failed to update restaurant: $e');
    }
  }

  @override
  Future<void> deleteRestaurant(String restaurantId) async {
    try {
      await _restaurantsRef.doc(restaurantId).delete();
    } catch (e) {
      throw ServerException('Failed to delete restaurant: $e');
    }
  }

  @override
  Future<void> toggleRestaurantStatus(
      String restaurantId, bool isActive) async {
    try {
      await _restaurantsRef.doc(restaurantId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Failed to toggle restaurant status: $e');
    }
  }

  @override
  Future<List<MenuItem>> getMenuItems(String restaurantId) async {
    try {
      final snapshot = await _restaurantsRef
          .doc(restaurantId)
          .collection(FirebaseConstants.menuItemsSubcollection)
          .orderBy('sortOrder')
          .get();
      return snapshot.docs.map(_menuItemFromDoc).toList();
    } catch (e) {
      throw ServerException('Failed to fetch menu items: $e');
    }
  }

  @override
  Future<MenuItem> addMenuItem(
    String restaurantId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['createdAt'] = FieldValue.serverTimestamp();
      final docRef = await _restaurantsRef
          .doc(restaurantId)
          .collection(FirebaseConstants.menuItemsSubcollection)
          .add(data);
      final doc = await docRef.get();
      return _menuItemFromDoc(doc);
    } catch (e) {
      throw ServerException('Failed to add menu item: $e');
    }
  }

  @override
  Future<MenuItem> updateMenuItem(
    String restaurantId,
    String menuItemId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _restaurantsRef
          .doc(restaurantId)
          .collection(FirebaseConstants.menuItemsSubcollection)
          .doc(menuItemId)
          .update(data);
      final doc = await _restaurantsRef
          .doc(restaurantId)
          .collection(FirebaseConstants.menuItemsSubcollection)
          .doc(menuItemId)
          .get();
      return _menuItemFromDoc(doc);
    } catch (e) {
      throw ServerException('Failed to update menu item: $e');
    }
  }

  @override
  Future<void> deleteMenuItem(
      String restaurantId, String menuItemId) async {
    try {
      await _restaurantsRef
          .doc(restaurantId)
          .collection(FirebaseConstants.menuItemsSubcollection)
          .doc(menuItemId)
          .delete();
    } catch (e) {
      throw ServerException('Failed to delete menu item: $e');
    }
  }
}
