import 'package:flutter/material.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/extensions/datetime_extensions.dart';
import 'package:tuish_food/core/widgets/cached_image.dart';
import 'package:tuish_food/core/widgets/rating_bar.dart';
import 'package:tuish_food/features/customer/reviews/domain/entities/review.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSizes.paddingAllM,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSizes.borderRadiusM,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer info row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                backgroundImage: review.reviewerPhotoUrl != null
                    ? NetworkImage(review.reviewerPhotoUrl!)
                    : null,
                child: review.reviewerPhotoUrl == null
                    ? Text(
                        (review.reviewerName ?? 'U')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName ?? 'Anonymous',
                      style: AppTypography.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      review.createdAt.timeAgo,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              TuishRatingBar(
                rating: review.rating,
                size: 16,
              ),
            ],
          ),

          // Comment
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.s12),
            Text(
              review.comment!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],

          // Sub-ratings
          if (_hasSubRatings) ...[
            const SizedBox(height: AppSizes.s12),
            Wrap(
              spacing: AppSizes.s16,
              runSpacing: AppSizes.s8,
              children: [
                if (review.foodRating != null)
                  _SubRatingChip(
                      label: 'Food', rating: review.foodRating!),
                if (review.packagingRating != null)
                  _SubRatingChip(
                      label: 'Packaging', rating: review.packagingRating!),
                if (review.valueRating != null)
                  _SubRatingChip(
                      label: 'Value', rating: review.valueRating!),
                if (review.punctualityRating != null)
                  _SubRatingChip(
                      label: 'Punctuality',
                      rating: review.punctualityRating!),
                if (review.courtesyRating != null)
                  _SubRatingChip(
                      label: 'Courtesy', rating: review.courtesyRating!),
              ],
            ),
          ],

          // Photos
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: AppSizes.s12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.imageUrls.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSizes.s8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: AppSizes.borderRadiusS,
                    child: CachedImage(
                      imageUrl: review.imageUrls[index],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool get _hasSubRatings =>
      review.foodRating != null ||
      review.packagingRating != null ||
      review.valueRating != null ||
      review.punctualityRating != null ||
      review.courtesyRating != null;
}

class _SubRatingChip extends StatelessWidget {
  const _SubRatingChip({required this.label, required this.rating});

  final String label;
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppSizes.s4),
        const Icon(Icons.star_rounded,
            size: 14, color: AppColors.starFilled),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
