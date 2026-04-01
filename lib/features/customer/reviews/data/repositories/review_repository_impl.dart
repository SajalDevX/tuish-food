import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/customer/reviews/data/datasources/review_remote_datasource.dart';
import 'package:tuish_food/features/customer/reviews/domain/entities/review.dart';
import 'package:tuish_food/features/customer/reviews/domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource _remoteDataSource;

  const ReviewRepositoryImpl(
      {required ReviewRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, void>> submitReview(Review review) async {
    try {
      await _remoteDataSource.submitReview(review);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Review>>> getReviews(
      String targetType, String targetId) async {
    try {
      final reviews =
          await _remoteDataSource.getReviews(targetType, targetId);
      return Right(reviews);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
