import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_item.dart';
import 'package:tuish_food/features/customer/menu/domain/repositories/menu_repository.dart';

class GetMenuItems {
  final MenuRepository repository;

  const GetMenuItems(this.repository);

  Future<Either<Failure, List<MenuItem>>> call(String restaurantId) {
    return repository.getMenuItems(restaurantId);
  }
}
