import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/reviews/domain/entities/review.dart';

abstract class ReviewRepository {
  Future<Either<Failure, void>> submitReview(Review review);
  Future<Either<Failure, List<Review>>> getReviews(
    String targetType,
    String targetId,
  );
}
