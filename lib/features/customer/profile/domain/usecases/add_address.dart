import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/profile/domain/entities/address.dart';
import 'package:tuish_food/features/customer/profile/domain/repositories/profile_repository.dart';

class AddAddress {
  final ProfileRepository repository;

  const AddAddress(this.repository);

  Future<Either<Failure, void>> call(String userId, Address address) {
    return repository.addAddress(userId, address);
  }
}
