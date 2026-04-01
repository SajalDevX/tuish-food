import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_item.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_category.dart';

abstract class MenuRepository {
  Future<Either<Failure, List<MenuItem>>> getMenuItems(String restaurantId);
  Future<Either<Failure, List<MenuCategory>>> getMenuCategories(
    String restaurantId,
  );
}
