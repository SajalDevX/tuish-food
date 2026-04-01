import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/enums/user_role.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/auth/domain/entities/app_user.dart';

abstract class UserManagementRepository {
  Future<Either<Failure, List<AppUser>>> getAllUsers({
    String? roleFilter,
    String? searchQuery,
  });

  Future<Either<Failure, AppUser>> getUserById(String id);

  Future<Either<Failure, void>> banUser(String userId);

  Future<Either<Failure, void>> unbanUser(String userId);

  Future<Either<Failure, void>> verifyDeliveryPartner(String userId);

  Future<Either<Failure, void>> updateUserRole(String userId, UserRole role);
}
