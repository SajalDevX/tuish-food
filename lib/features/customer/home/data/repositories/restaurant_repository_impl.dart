import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/home/data/datasources/restaurant_remote_datasource.dart';
import 'package:tuish_food/features/customer/home/domain/entities/category.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';
import 'package:tuish_food/features/customer/home/domain/repositories/restaurant_repository.dart';

class RestaurantRepositoryImpl implements RestaurantRepository {
  final RestaurantRemoteDatasource remoteDatasource;

  const RestaurantRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, List<Restaurant>>> getNearbyRestaurants({
    required double lat,
    required double lng,
    double radiusKm = 10.0,
  }) async {
    try {
      final restaurants = await remoteDatasource.getNearbyRestaurants(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
      );
      return Right(restaurants);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Restaurant>> getRestaurantById(String id) async {
    try {
      final restaurant = await remoteDatasource.getRestaurantById(id);
      return Right(restaurant);
    } on ServerException catch (e) {
      if (e.message.contains('not found')) {
        return Left(NotFoundFailure(e.message));
      }
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Restaurant>>> searchRestaurants(
    String query,
  ) async {
    try {
      final restaurants = await remoteDatasource.searchRestaurants(query);
      return Right(restaurants);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FoodCategory>>> getCategories() async {
    try {
      final categories = await remoteDatasource.getCategories();
      return Right(categories);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Restaurant>>> getRestaurantsByCategory(
    String category,
  ) async {
    try {
      final restaurants =
          await remoteDatasource.getRestaurantsByCategory(category);
      return Right(restaurants);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Restaurant> watchRestaurant(String id) {
    return remoteDatasource.watchRestaurant(id);
  }
}
