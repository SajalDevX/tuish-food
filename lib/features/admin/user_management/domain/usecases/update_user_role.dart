import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/enums/user_role.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/admin/user_management/domain/repositories/user_management_repository.dart';

class UpdateUserRole {
  final UserManagementRepository repository;

  const UpdateUserRole(this.repository);

  Future<Either<Failure, void>> call(String userId, UserRole role) {
    return repository.updateUserRole(userId, role);
  }
}
