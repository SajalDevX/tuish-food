import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/menu/data/datasources/menu_remote_datasource.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_item.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_category.dart';
import 'package:tuish_food/features/customer/menu/domain/repositories/menu_repository.dart';

class MenuRepositoryImpl implements MenuRepository {
  final MenuRemoteDatasource remoteDatasource;

  const MenuRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, List<MenuItem>>> getMenuItems(
    String restaurantId,
  ) async {
    try {
      final items = await remoteDatasource.getMenuItems(restaurantId);
      return Right(items);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MenuCategory>>> getMenuCategories(
    String restaurantId,
  ) async {
    try {
      final categories = await remoteDatasource.getMenuCategories(restaurantId);
      return Right(categories);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
