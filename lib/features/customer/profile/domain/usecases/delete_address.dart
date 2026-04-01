import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/profile/domain/repositories/profile_repository.dart';

class DeleteAddress {
  final ProfileRepository repository;

  const DeleteAddress(this.repository);

  Future<Either<Failure, void>> call(String userId, String addressId) {
    return repository.deleteAddress(userId, addressId);
  }
}
