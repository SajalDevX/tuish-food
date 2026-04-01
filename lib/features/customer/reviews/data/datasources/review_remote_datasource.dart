import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/features/customer/reviews/data/models/review_model.dart';
import 'package:tuish_food/features/customer/reviews/domain/entities/review.dart';

abstract class ReviewRemoteDataSource {
  Future<void> submitReview(Review review);
  Future<List<ReviewModel>> getReviews(String targetType, String targetId);
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  final FirebaseFirestore _firestore;

  const ReviewRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference get _reviewsRef =>
      _firestore.collection(FirebaseConstants.reviewsCollection);

  @override
  Future<void> submitReview(Review review) async {
    try {
      final model = ReviewModel.fromEntity(review);
      if (review.id.isEmpty) {
        await _reviewsRef.add(model.toFirestore());
      } else {
        await _reviewsRef.doc(review.id).set(model.toFirestore());
      }
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to submit review');
    }
  }

  @override
  Future<List<ReviewModel>> getReviews(
      String targetType, String targetId) async {
    try {
      final snapshot = await _reviewsRef
          .where('targetType', isEqualTo: targetType)
          .where('targetId', isEqualTo: targetId)
          .where('isVisible', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to fetch reviews');
    }
  }
}
