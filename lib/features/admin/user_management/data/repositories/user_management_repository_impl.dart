import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/enums/user_role.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/admin/user_management/data/datasources/user_management_datasource.dart';
import 'package:tuish_food/features/admin/user_management/domain/repositories/user_management_repository.dart';
import 'package:tuish_food/features/auth/domain/entities/app_user.dart';

class UserManagementRepositoryImpl implements UserManagementRepository {
  final UserManagementDatasource _datasource;

  const UserManagementRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<AppUser>>> getAllUsers({
    String? roleFilter,
    String? searchQuery,
  }) async {
    try {
      final users = await _datasource.getAllUsers(
        roleFilter: roleFilter,
        searchQuery: searchQuery,
      );
      return Right(users);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> getUserById(String id) async {
    try {
      final user = await _datasource.getUserById(id);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> banUser(String userId) async {
    try {
      await _datasource.banUser(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unbanUser(String userId) async {
    try {
      await _datasource.unbanUser(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyDeliveryPartner(String userId) async {
    try {
      await _datasource.verifyDeliveryPartner(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserRole(
    String userId,
    UserRole role,
  ) async {
    try {
      await _datasource.updateUserRole(userId, role);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
