import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/reviews/domain/entities/review.dart';
import 'package:tuish_food/features/customer/reviews/domain/repositories/review_repository.dart';

class GetReviews {
  final ReviewRepository repository;

  const GetReviews(this.repository);

  Future<Either<Failure, List<Review>>> call(
    String targetType,
    String targetId,
  ) {
    return repository.getReviews(targetType, targetId);
  }
}
