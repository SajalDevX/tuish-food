import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/features/admin/restaurant_management/data/datasources/admin_restaurant_datasource.dart';
import 'package:tuish_food/features/admin/restaurant_management/data/repositories/admin_restaurant_repository_impl.dart';
import 'package:tuish_food/features/admin/restaurant_management/domain/repositories/admin_restaurant_repository.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_item.dart';
import 'package:tuish_food/injection_container.dart';

// Datasource
final adminRestaurantDatasourceProvider =
    Provider<AdminRestaurantDatasource>((ref) {
  return AdminRestaurantDatasourceImpl(ref.watch(firestoreProvider));
});

// Repository
final adminRestaurantRepositoryProvider =
    Provider<AdminRestaurantRepository>((ref) {
  return AdminRestaurantRepositoryImpl(
      ref.watch(adminRestaurantDatasourceProvider));
});

// All restaurants
final allRestaurantsProvider =
    FutureProvider.autoDispose<List<Restaurant>>((ref) async {
  final repo = ref.watch(adminRestaurantRepositoryProvider);
  final result = await repo.getAllRestaurants();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (restaurants) => restaurants,
  );
});

// Restaurant filter state
class RestaurantFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void update(String value) {
    state = value;
  }
}

final restaurantFilterProvider =
    NotifierProvider<RestaurantFilterNotifier, String>(
        RestaurantFilterNotifier.new);

class RestaurantSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) {
    state = value;
  }
}

final restaurantSearchProvider =
    NotifierProvider<RestaurantSearchNotifier, String>(
        RestaurantSearchNotifier.new);

// Filtered restaurants
final filteredRestaurantsProvider =
    Provider.autoDispose<AsyncValue<List<Restaurant>>>((ref) {
  final restaurantsAsync = ref.watch(allRestaurantsProvider);
  final filter = ref.watch(restaurantFilterProvider);
  final search = ref.watch(restaurantSearchProvider).toLowerCase();

  return restaurantsAsync.whenData((restaurants) {
    var filtered = restaurants;

    // Filter by status
    if (filter == 'active') {
      filtered = filtered.where((r) => r.isActive).toList();
    } else if (filter == 'inactive') {
      filtered = filtered.where((r) => !r.isActive).toList();
    }

    // Filter by search
    if (search.isNotEmpty) {
      filtered = filtered
          .where((r) =>
              r.name.toLowerCase().contains(search) ||
              r.cuisineTypes
                  .any((c) => c.toLowerCase().contains(search)))
          .toList();
    }

    return filtered;
  });
});

// Restaurant CRUD notifier
class RestaurantCrudNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  AdminRestaurantRepository get _repository =>
      ref.watch(adminRestaurantRepositoryProvider);

  Future<bool> createRestaurant(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repository.createRestaurant(data);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(allRestaurantsProvider);
        return true;
      },
    );
  }

  Future<bool> updateRestaurant(
    String restaurantId,
    Map<String, dynamic> data,
  ) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateRestaurant(restaurantId, data);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(allRestaurantsProvider);
        return true;
      },
    );
  }

  Future<bool> deleteRestaurant(String restaurantId) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteRestaurant(restaurantId);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(allRestaurantsProvider);
        return true;
      },
    );
  }

  Future<bool> toggleStatus(String restaurantId, bool isActive) async {
    state = const AsyncValue.loading();
    final result =
        await _repository.toggleRestaurantStatus(restaurantId, isActive);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(allRestaurantsProvider);
        return true;
      },
    );
  }
}

final restaurantCrudProvider =
    NotifierProvider<RestaurantCrudNotifier, AsyncValue<void>>(
        RestaurantCrudNotifier.new);

// Menu items for a restaurant
final menuItemsProvider = FutureProvider.autoDispose
    .family<List<MenuItem>, String>((ref, restaurantId) async {
  final repo = ref.watch(adminRestaurantRepositoryProvider);
  final result = await repo.getMenuItems(restaurantId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (items) => items,
  );
});

// Menu CRUD notifier
class MenuCrudNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  AdminRestaurantRepository get _repository =>
      ref.watch(adminRestaurantRepositoryProvider);

  Future<bool> addMenuItem(
    String restaurantId,
    Map<String, dynamic> data,
  ) async {
    state = const AsyncValue.loading();
    final result = await _repository.addMenuItem(restaurantId, data);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(menuItemsProvider(restaurantId));
        return true;
      },
    );
  }

  Future<bool> updateMenuItem(
    String restaurantId,
    String menuItemId,
    Map<String, dynamic> data,
  ) async {
    state = const AsyncValue.loading();
    final result =
        await _repository.updateMenuItem(restaurantId, menuItemId, data);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(menuItemsProvider(restaurantId));
        return true;
      },
    );
  }

  Future<bool> deleteMenuItem(
    String restaurantId,
    String menuItemId,
  ) async {
    state = const AsyncValue.loading();
    final result =
        await _repository.deleteMenuItem(restaurantId, menuItemId);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(menuItemsProvider(restaurantId));
        return true;
      },
    );
  }
}

final menuCrudProvider =
    NotifierProvider<MenuCrudNotifier, AsyncValue<void>>(
        MenuCrudNotifier.new);
