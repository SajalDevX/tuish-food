import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/auth/domain/entities/app_user.dart';
import 'package:tuish_food/features/auth/domain/repositories/auth_repository.dart';

class SignInWithEmail {
  final AuthRepository repository;

  const SignInWithEmail(this.repository);

  Future<Either<Failure, AppUser>> call(String email, String password) {
    return repository.signInWithEmail(email, password);
  }
}
