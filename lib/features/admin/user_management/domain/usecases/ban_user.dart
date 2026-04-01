import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/admin/user_management/domain/repositories/user_management_repository.dart';

class BanUser {
  final UserManagementRepository repository;

  const BanUser(this.repository);

  Future<Either<Failure, void>> call(String userId) {
    return repository.banUser(userId);
  }
}
