import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String id;
  final String orderId;
  final String reviewerId;
  final String? reviewerName;
  final String? reviewerPhotoUrl;
  final String targetType; // 'restaurant' | 'deliveryPartner'
  final String targetId;
  final double rating;
  final String? comment;
  final List<String> imageUrls;
  final double? foodRating;
  final double? packagingRating;
  final double? valueRating;
  final double? punctualityRating;
  final double? courtesyRating;
  final bool isVisible;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.orderId,
    required this.reviewerId,
    this.reviewerName,
    this.reviewerPhotoUrl,
    required this.targetType,
    required this.targetId,
    required this.rating,
    this.comment,
    this.imageUrls = const [],
    this.foodRating,
    this.packagingRating,
    this.valueRating,
    this.punctualityRating,
    this.courtesyRating,
    this.isVisible = true,
    required this.createdAt,
  });

  bool get isRestaurantReview => targetType == 'restaurant';
  bool get isDeliveryPartnerReview => targetType == 'deliveryPartner';

  @override
  List<Object?> get props => [
        id,
        orderId,
        reviewerId,
        reviewerName,
        reviewerPhotoUrl,
        targetType,
        targetId,
        rating,
        comment,
        imageUrls,
        foodRating,
        packagingRating,
        valueRating,
        punctualityRating,
        courtesyRating,
        isVisible,
        createdAt,
      ];
}
