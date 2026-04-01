import 'package:flutter/material.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/rating_bar.dart';
import 'package:tuish_food/features/customer/reviews/domain/entities/review.dart';

class ReviewSummary extends StatelessWidget {
  const ReviewSummary({super.key, required this.reviews});

  final List<Review> reviews;

  double get _averageRating {
    if (reviews.isEmpty) return 0;
    final total = reviews.fold(0.0, (sum, r) => sum + r.rating);
    return total / reviews.length;
  }

  Map<int, int> get _ratingDistribution {
    final distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in reviews) {
      final rounded = review.rating.round().clamp(1, 5);
      distribution[rounded] = (distribution[rounded] ?? 0) + 1;
    }
    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Container(
        padding: AppSizes.paddingAllM,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppSizes.borderRadiusM,
        ),
        child: Center(
          child: Text(
            'No reviews yet',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final distribution = _ratingDistribution;
    final average = _averageRating;

    return Container(
      padding: AppSizes.paddingAllM,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppSizes.borderRadiusM,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Average rating
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  average.toStringAsFixed(1),
                  style: AppTypography.displaySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.s4),
                TuishRatingBar(
                  rating: average,
                  size: 18,
                ),
                const SizedBox(height: AppSizes.s4),
                Text(
                  '${reviews.length} review${reviews.length != 1 ? 's' : ''}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSizes.s16),

          // Distribution bars
          Expanded(
            flex: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [5, 4, 3, 2, 1].map((star) {
                final count = distribution[star] ?? 0;
                final percentage =
                    reviews.isNotEmpty ? count / reviews.length : 0.0;
                return _RatingBar(
                  star: star,
                  count: count,
                  percentage: percentage,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({
    required this.star,
    required this.count,
    required this.percentage,
  });

  final int star;
  final int count;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Text(
              '$star',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.star_rounded,
              size: 12, color: AppColors.starFilled),
          const SizedBox(width: AppSizes.s8),
          Expanded(
            child: ClipRRect(
              borderRadius: AppSizes.borderRadiusPill,
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: AppColors.divider,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.starFilled),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.s8),
          SizedBox(
            width: 24,
            child: Text(
              '$count',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
