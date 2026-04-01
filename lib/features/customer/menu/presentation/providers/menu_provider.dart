import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuish_food/features/customer/menu/data/datasources/menu_remote_datasource.dart';
import 'package:tuish_food/features/customer/menu/data/repositories/menu_repository_impl.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_category.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_item.dart';
import 'package:tuish_food/features/customer/menu/domain/repositories/menu_repository.dart';
import 'package:tuish_food/injection_container.dart';

final menuRemoteDatasourceProvider = Provider<MenuRemoteDatasource>((ref) {
  return MenuRemoteDatasourceImpl(firestore: ref.watch(firestoreProvider));
});

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepositoryImpl(
    remoteDatasource: ref.watch(menuRemoteDatasourceProvider),
  );
});

final menuItemsProvider = FutureProvider.family<List<MenuItem>, String>((
  ref,
  restaurantId,
) async {
  final repository = ref.watch(menuRepositoryProvider);
  final result = await repository.getMenuItems(restaurantId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (items) => items,
  );
});

final menuCategoriesProvider =
    FutureProvider.family<List<MenuCategory>, String>((
      ref,
      restaurantId,
    ) async {
      final repository = ref.watch(menuRepositoryProvider);
      final result = await repository.getMenuCategories(restaurantId);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (categories) => categories.where((c) => c.isActive).toList(),
      );
    });

/// Tracks the currently selected veg/non-veg filter.
/// null = show all, true = veg only, false = non-veg only
class VegFilterNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;

  void update(bool? value) {
    state = value;
  }
}

final vegFilterProvider =
    NotifierProvider<VegFilterNotifier, bool?>(VegFilterNotifier.new);
