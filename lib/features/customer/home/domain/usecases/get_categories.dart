import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/home/domain/entities/category.dart';
import 'package:tuish_food/features/customer/home/domain/repositories/restaurant_repository.dart';

class GetCategories {
  final RestaurantRepository repository;

  const GetCategories(this.repository);

  Future<Either<Failure, List<FoodCategory>>> call() {
    return repository.getCategories();
  }
}
