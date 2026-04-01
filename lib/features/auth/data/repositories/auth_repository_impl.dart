import 'dart:async';

import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/enums/user_role.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:tuish_food/features/auth/domain/entities/app_user.dart';
import 'package:tuish_food/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  const AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AppUser>> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final user = await remoteDataSource.signInWithEmail(email, password);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final user = await remoteDataSource.signUpWithEmail(
        email,
        password,
        displayName,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signInWithPhone(String phoneNumber) async {
    final completer = Completer<Either<Failure, void>>();

    try {
      await remoteDataSource.signInWithPhone(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId, resendToken) {
          if (!completer.isCompleted) {
            completer.complete(const Right(null));
          }
        },
        onError: (message) {
          if (!completer.isCompleted) {
            completer.complete(Left(AuthFailure(message)));
          }
        },
      );

      // If neither callback was called, we still need to complete
      // Wait a short time to allow callbacks to fire
      return await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => const Left(
          AuthFailure('Phone verification timed out. Please try again.'),
        ),
      );
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> verifyOtp(
    String verificationId,
    String otp,
  ) async {
    try {
      final user = await remoteDataSource.verifyOtp(verificationId, otp);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await remoteDataSource.resetPassword(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return remoteDataSource.authStateChanges();
  }

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserRole?>> getUserRole() async {
    try {
      final role = await remoteDataSource.getUserRole();
      return Right(role);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
