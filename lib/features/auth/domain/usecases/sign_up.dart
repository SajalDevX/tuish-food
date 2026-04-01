import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/auth/domain/entities/app_user.dart';
import 'package:tuish_food/features/auth/domain/repositories/auth_repository.dart';

class SignUp {
  final AuthRepository repository;

  const SignUp(this.repository);

  Future<Either<Failure, AppUser>> call(
    String email,
    String password,
    String displayName,
  ) {
    return repository.signUpWithEmail(email, password, displayName);
  }
}
