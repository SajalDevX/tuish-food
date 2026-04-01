import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/admin/user_management/domain/repositories/user_management_repository.dart';

class VerifyDeliveryPartner {
  final UserManagementRepository repository;

  const VerifyDeliveryPartner(this.repository);

  Future<Either<Failure, void>> call(String userId) {
    return repository.verifyDeliveryPartner(userId);
  }
}
