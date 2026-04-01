import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/admin/restaurant_management/domain/repositories/admin_restaurant_repository.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_item.dart';

class GetMenuItemsAdmin {
  final AdminRestaurantRepository repository;

  const GetMenuItemsAdmin(this.repository);

  Future<Either<Failure, List<MenuItem>>> call(String restaurantId) {
    return repository.getMenuItems(restaurantId);
  }
}

class AddMenuItem {
  final AdminRestaurantRepository repository;

  const AddMenuItem(this.repository);

  Future<Either<Failure, MenuItem>> call(
    String restaurantId,
    Map<String, dynamic> data,
  ) {
    return repository.addMenuItem(restaurantId, data);
  }
}

class UpdateMenuItem {
  final AdminRestaurantRepository repository;

  const UpdateMenuItem(this.repository);

  Future<Either<Failure, MenuItem>> call(
    String restaurantId,
    String menuItemId,
    Map<String, dynamic> data,
  ) {
    return repository.updateMenuItem(restaurantId, menuItemId, data);
  }
}

class DeleteMenuItem {
  final AdminRestaurantRepository repository;

  const DeleteMenuItem(this.repository);

  Future<Either<Failure, void>> call(
    String restaurantId,
    String menuItemId,
  ) {
    return repository.deleteMenuItem(restaurantId, menuItemId);
  }
}
