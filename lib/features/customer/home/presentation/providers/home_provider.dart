import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuish_food/features/customer/home/data/datasources/restaurant_remote_datasource.dart';
import 'package:tuish_food/features/customer/home/data/repositories/restaurant_repository_impl.dart';
import 'package:tuish_food/features/customer/home/domain/entities/category.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';
import 'package:tuish_food/features/customer/home/domain/repositories/restaurant_repository.dart';
import 'package:tuish_food/injection_container.dart';

// ---------------------------------------------------------------------------
// Data layer providers
// ---------------------------------------------------------------------------

final restaurantRemoteDatasourceProvider =
    Provider<RestaurantRemoteDatasource>((ref) {
  return RestaurantRemoteDatasourceImpl(
    firestore: ref.watch(firestoreProvider),
  );
});

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return RestaurantRepositoryImpl(
    remoteDatasource: ref.watch(restaurantRemoteDatasourceProvider),
  );
});

// ---------------------------------------------------------------------------
// Presentation layer providers
// ---------------------------------------------------------------------------

/// Fetches nearby restaurants. Uses a default location; in production,
/// you would pass the user's actual coordinates.
final nearbyRestaurantsProvider =
    FutureProvider<List<Restaurant>>((ref) async {
  final repository = ref.watch(restaurantRepositoryProvider);

  // Default coordinates (can be replaced with user's location)
  final result = await repository.getNearbyRestaurants(
    lat: 0.0,
    lng: 0.0,
    radiusKm: 10.0,
  );

  return result.fold(
    (failure) => throw Exception(failure.message),
    (restaurants) => restaurants,
  );
});

/// Fetches a single restaurant by its id.
final restaurantDetailProvider =
    FutureProvider.family<Restaurant, String>((ref, id) async {
  final repository = ref.watch(restaurantRepositoryProvider);

  final result = await repository.getRestaurantById(id);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (restaurant) => restaurant,
  );
});

/// Fetches the list of food categories.
final categoriesProvider = FutureProvider<List<FoodCategory>>((ref) async {
  final repository = ref.watch(restaurantRepositoryProvider);

  final result = await repository.getCategories();

  return result.fold(
    (failure) => throw Exception(failure.message),
    (categories) => categories,
  );
});

/// Fetches restaurants filtered by a specific category.
final restaurantsByCategoryProvider =
    FutureProvider.family<List<Restaurant>, String>((ref, category) async {
  final repository = ref.watch(restaurantRepositoryProvider);

  final result = await repository.getRestaurantsByCategory(category);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (restaurants) => restaurants,
  );
});
