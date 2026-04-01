import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/auth/domain/repositories/auth_repository.dart';

class SignInWithPhone {
  final AuthRepository repository;

  const SignInWithPhone(this.repository);

  Future<Either<Failure, void>> call(String phoneNumber) {
    return repository.signInWithPhone(phoneNumber);
  }
}
