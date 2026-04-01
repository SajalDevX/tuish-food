import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/reviews/domain/entities/review.dart';
import 'package:tuish_food/features/customer/reviews/domain/repositories/review_repository.dart';

class SubmitReview {
  final ReviewRepository repository;

  const SubmitReview(this.repository);

  Future<Either<Failure, void>> call(Review review) {
    return repository.submitReview(review);
  }
}
