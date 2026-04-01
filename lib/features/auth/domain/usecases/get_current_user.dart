import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/auth/domain/entities/app_user.dart';
import 'package:tuish_food/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUser {
  final AuthRepository repository;

  const GetCurrentUser(this.repository);

  Future<Either<Failure, AppUser?>> call() {
    return repository.getCurrentUser();
  }
}
