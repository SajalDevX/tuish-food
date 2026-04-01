import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/profile/domain/repositories/profile_repository.dart';

class UpdateProfile {
  final ProfileRepository repository;

  const UpdateProfile(this.repository);

  Future<Either<Failure, void>> call({
    required String userId,
    String? displayName,
    String? email,
    String? phone,
    String? photoUrl,
  }) {
    return repository.updateProfile(
      userId: userId,
      displayName: displayName,
      email: email,
      phone: phone,
      photoUrl: photoUrl,
    );
  }
}
