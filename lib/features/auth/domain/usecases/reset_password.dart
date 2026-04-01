import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/auth/domain/repositories/auth_repository.dart';

class ResetPassword {
  final AuthRepository repository;

  const ResetPassword(this.repository);

  Future<Either<Failure, void>> call(String email) {
    return repository.resetPassword(email);
  }
}
