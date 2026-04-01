import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/admin/restaurant_management/data/datasources/admin_restaurant_datasource.dart';
import 'package:tuish_food/features/admin/restaurant_management/domain/repositories/admin_restaurant_repository.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_item.dart';

class AdminRestaurantRepositoryImpl implements AdminRestaurantRepository {
  final AdminRestaurantDatasource _datasource;

  const AdminRestaurantRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<Restaurant>>> getAllRestaurants() async {
    try {
      final result = await _datasource.getAllRestaurants();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Restaurant>> createRestaurant(
      Map<String, dynamic> data) async {
    try {
      final result = await _datasource.createRestaurant(data);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Restaurant>> updateRestaurant(
    String restaurantId,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _datasource.updateRestaurant(restaurantId, data);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRestaurant(String restaurantId) async {
    try {
      await _datasource.deleteRestaurant(restaurantId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleRestaurantStatus(
    String restaurantId,
    bool isActive,
  ) async {
    try {
      await _datasource.toggleRestaurantStatus(restaurantId, isActive);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MenuItem>>> getMenuItems(
      String restaurantId) async {
    try {
      final result = await _datasource.getMenuItems(restaurantId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MenuItem>> addMenuItem(
    String restaurantId,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _datasource.addMenuItem(restaurantId, data);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MenuItem>> updateMenuItem(
    String restaurantId,
    String menuItemId,
    Map<String, dynamic> data,
  ) async {
    try {
      final result =
          await _datasource.updateMenuItem(restaurantId, menuItemId, data);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMenuItem(
    String restaurantId,
    String menuItemId,
  ) async {
    try {
      await _datasource.deleteMenuItem(restaurantId, menuItemId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
