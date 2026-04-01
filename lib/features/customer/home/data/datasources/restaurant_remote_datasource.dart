import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/features/customer/home/data/models/category_model.dart';
import 'package:tuish_food/features/customer/home/data/models/restaurant_model.dart';

abstract class RestaurantRemoteDatasource {
  /// Fetches restaurants near the given coordinates within [radiusKm].
  Future<List<RestaurantModel>> getNearbyRestaurants({
    required double lat,
    required double lng,
    double radiusKm = 10.0,
  });

  /// Fetches a single restaurant by its Firestore document id.
  Future<RestaurantModel> getRestaurantById(String id);

  /// Searches restaurants whose name contains [query] (case-insensitive prefix).
  Future<List<RestaurantModel>> searchRestaurants(String query);

  /// Returns the predefined list of food categories.
  Future<List<CategoryModel>> getCategories();

  /// Returns restaurants whose cuisineTypes array contains [category].
  Future<List<RestaurantModel>> getRestaurantsByCategory(String category);

  /// Streams real-time updates for a single restaurant document.
  Stream<RestaurantModel> watchRestaurant(String id);
}

class RestaurantRemoteDatasourceImpl implements RestaurantRemoteDatasource {
  final FirebaseFirestore firestore;

  RestaurantRemoteDatasourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> get _restaurantsRef =>
      firestore.collection(FirebaseConstants.restaurantsCollection);

  @override
  Future<List<RestaurantModel>> getNearbyRestaurants({
    required double lat,
    required double lng,
    double radiusKm = 10.0,
  }) async {
    try {
      // Query active restaurants, ordered by rating.
      // For production, integrate geoflutterfire_plus for precise geo queries.
      // Here we fetch active restaurants and could filter by distance client-side.
      final snapshot = await _restaurantsRef
          .where('isActive', isEqualTo: true)
          .orderBy('averageRating', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => RestaurantModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to fetch nearby restaurants');
    } catch (e) {
      throw ServerException('Failed to fetch nearby restaurants: $e');
    }
  }

  @override
  Future<RestaurantModel> getRestaurantById(String id) async {
    try {
      final doc = await _restaurantsRef.doc(id).get();

      if (!doc.exists) {
        throw const ServerException('Restaurant not found');
      }

      return RestaurantModel.fromFirestore(doc);
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to fetch restaurant');
    } catch (e) {
      throw ServerException('Failed to fetch restaurant: $e');
    }
  }

  @override
  Future<List<RestaurantModel>> searchRestaurants(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      // Firestore prefix search: name >= query && name < query + high Unicode char
      final searchTerm = query.trim().toLowerCase();
      final endTerm = '$searchTerm\uf8ff';

      final snapshot = await _restaurantsRef
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .startAt([searchTerm])
          .endAt([endTerm])
          .limit(20)
          .get();

      // Also search by tags/cuisineTypes for broader results
      final tagSnapshot = await _restaurantsRef
          .where('isActive', isEqualTo: true)
          .where('tags', arrayContains: searchTerm)
          .limit(10)
          .get();

      final resultsMap = <String, RestaurantModel>{};

      for (final doc in snapshot.docs) {
        final model = RestaurantModel.fromFirestore(doc);
        resultsMap[model.id] = model;
      }

      for (final doc in tagSnapshot.docs) {
        final model = RestaurantModel.fromFirestore(doc);
        resultsMap.putIfAbsent(model.id, () => model);
      }

      return resultsMap.values.toList();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to search restaurants');
    } catch (e) {
      throw ServerException('Failed to search restaurants: $e');
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    // Return predefined categories. In a production app, these could come
    // from a Firestore collection or remote config.
    return CategoryModel.predefinedCategories;
  }

  @override
  Future<List<RestaurantModel>> getRestaurantsByCategory(
    String category,
  ) async {
    try {
      final snapshot = await _restaurantsRef
          .where('isActive', isEqualTo: true)
          .where('cuisineTypes', arrayContains: category.toLowerCase())
          .orderBy('averageRating', descending: true)
          .limit(30)
          .get();

      return snapshot.docs
          .map((doc) => RestaurantModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch restaurants by category',
      );
    } catch (e) {
      throw ServerException('Failed to fetch restaurants by category: $e');
    }
  }

  @override
  Stream<RestaurantModel> watchRestaurant(String id) {
    return _restaurantsRef.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        throw const ServerException('Restaurant not found');
      }
      return RestaurantModel.fromFirestore(snapshot);
    });
  }
}
