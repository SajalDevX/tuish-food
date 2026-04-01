import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/profile/domain/entities/address.dart';

abstract class ProfileRepository {
  Future<Either<Failure, void>> updateProfile({
    required String userId,
    String? displayName,
    String? email,
    String? phone,
    String? photoUrl,
  });

  Future<Either<Failure, List<Address>>> getAddresses(String userId);

  Future<Either<Failure, void>> addAddress(String userId, Address address);

  Future<Either<Failure, void>> deleteAddress(
      String userId, String addressId);

  Future<Either<Failure, void>> setDefaultAddress(
      String userId, String addressId);
}
