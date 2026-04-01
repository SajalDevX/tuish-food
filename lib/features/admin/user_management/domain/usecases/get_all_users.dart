import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/admin/user_management/domain/repositories/user_management_repository.dart';
import 'package:tuish_food/features/auth/domain/entities/app_user.dart';

class GetAllUsers {
  final UserManagementRepository repository;

  const GetAllUsers(this.repository);

  Future<Either<Failure, List<AppUser>>> call({
    String? roleFilter,
    String? searchQuery,
  }) {
    return repository.getAllUsers(
      roleFilter: roleFilter,
      searchQuery: searchQuery,
    );
  }
}
