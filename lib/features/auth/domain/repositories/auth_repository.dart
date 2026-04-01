import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/enums/user_role.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AppUser>> signInWithEmail(
    String email,
    String password,
  );

  Future<Either<Failure, AppUser>> signUpWithEmail(
    String email,
    String password,
    String displayName,
  );

  Future<Either<Failure, void>> signInWithPhone(String phoneNumber);

  Future<Either<Failure, AppUser>> verifyOtp(
    String verificationId,
    String otp,
  );

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, void>> resetPassword(String email);

  Stream<AppUser?> authStateChanges();

  Future<Either<Failure, AppUser?>> getCurrentUser();

  Future<Either<Failure, UserRole?>> getUserRole();
}
