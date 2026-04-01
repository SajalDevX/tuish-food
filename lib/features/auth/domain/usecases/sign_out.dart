import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/auth/domain/repositories/auth_repository.dart';

class SignOut {
  final AuthRepository repository;

  const SignOut(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.signOut();
  }
}
