import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tuish_food/features/customer/reviews/domain/entities/review.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.orderId,
    required super.reviewerId,
    super.reviewerName,
    super.reviewerPhotoUrl,
    required super.targetType,
    required super.targetId,
    required super.rating,
    super.comment,
    super.imageUrls,
    super.foodRating,
    super.packagingRating,
    super.valueRating,
    super.punctualityRating,
    super.courtesyRating,
    super.isVisible,
    required super.createdAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ReviewModel(
      id: doc.id,
      orderId: data['orderId'] as String? ?? '',
      reviewerId: data['reviewerId'] as String? ?? '',
      reviewerName: data['reviewerName'] as String?,
      reviewerPhotoUrl: data['reviewerPhotoUrl'] as String?,
      targetType: data['targetType'] as String? ?? 'restaurant',
      targetId: data['targetId'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      comment: data['comment'] as String?,
      imageUrls: (data['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      foodRating: (data['foodRating'] as num?)?.toDouble(),
      packagingRating: (data['packagingRating'] as num?)?.toDouble(),
      valueRating: (data['valueRating'] as num?)?.toDouble(),
      punctualityRating: (data['punctualityRating'] as num?)?.toDouble(),
      courtesyRating: (data['courtesyRating'] as num?)?.toDouble(),
      isVisible: data['isVisible'] as bool? ?? true,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerPhotoUrl': reviewerPhotoUrl,
      'targetType': targetType,
      'targetId': targetId,
      'rating': rating,
      'comment': comment,
      'imageUrls': imageUrls,
      'foodRating': foodRating,
      'packagingRating': packagingRating,
      'valueRating': valueRating,
      'punctualityRating': punctualityRating,
      'courtesyRating': courtesyRating,
      'isVisible': isVisible,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReviewModel.fromEntity(Review review) {
    return ReviewModel(
      id: review.id,
      orderId: review.orderId,
      reviewerId: review.reviewerId,
      reviewerName: review.reviewerName,
      reviewerPhotoUrl: review.reviewerPhotoUrl,
      targetType: review.targetType,
      targetId: review.targetId,
      rating: review.rating,
      comment: review.comment,
      imageUrls: review.imageUrls,
      foodRating: review.foodRating,
      packagingRating: review.packagingRating,
      valueRating: review.valueRating,
      punctualityRating: review.punctualityRating,
      courtesyRating: review.courtesyRating,
      isVisible: review.isVisible,
      createdAt: review.createdAt,
    );
  }
}
