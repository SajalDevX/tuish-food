import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_category.dart';
import 'package:tuish_food/features/customer/menu/domain/repositories/menu_repository.dart';

class GetMenuCategories {
  final MenuRepository repository;

  const GetMenuCategories(this.repository);

  Future<Either<Failure, List<MenuCategory>>> call(String restaurantId) {
    return repository.getMenuCategories(restaurantId);
  }
}
