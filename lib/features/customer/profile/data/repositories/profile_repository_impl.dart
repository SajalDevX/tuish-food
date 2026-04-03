import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/profile/data/datasources/profile_remote_datasource.dart';
import 'package:tuish_food/features/customer/profile/domain/entities/address.dart';
import 'package:tuish_food/features/customer/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  const ProfileRepositoryImpl(
      {required ProfileRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, void>> updateProfile({
    required String userId,
    String? displayName,
    String? email,
    String? phone,
    String? photoUrl,
  }) async {
    try {
      await _remoteDataSource.updateProfile(
        userId: userId,
        displayName: displayName,
        email: email,
        phone: phone,
        photoUrl: photoUrl,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Address>>> getAddresses(String userId) async {
    try {
      final addresses = await _remoteDataSource.getAddresses(userId);
      return Right(addresses);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> addAddress(
      String userId, Address address) async {
    try {
      await _remoteDataSource.addAddress(userId, address);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAddress(
      String userId, String addressId) async {
    try {
      await _remoteDataSource.deleteAddress(userId, addressId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> setDefaultAddress(
      String userId, String addressId) async {
    try {
      await _remoteDataSource.setDefaultAddress(userId, addressId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateAddress(
      String userId, Address address) async {
    try {
      await _remoteDataSource.updateAddress(userId, address);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
