import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/profile/domain/entities/address.dart';
import 'package:tuish_food/features/customer/profile/domain/repositories/profile_repository.dart';

class GetAddresses {
  final ProfileRepository repository;

  const GetAddresses(this.repository);

  Future<Either<Failure, List<Address>>> call(String userId) {
    return repository.getAddresses(userId);
  }
}
