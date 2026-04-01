import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';

class TuishRatingBar extends StatelessWidget {
  const TuishRatingBar({
    super.key,
    required this.rating,
    this.size,
    this.onRatingUpdate,
    this.itemCount = 5,
  });

  /// The current rating value.
  final double rating;

  /// Size of each star icon. Defaults to [AppSizes.iconM].
  final double? size;

  /// If non-null, the rating bar becomes interactive.
  /// If null, the rating bar is display-only.
  final ValueChanged<double>? onRatingUpdate;

  /// Number of stars. Defaults to 5.
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? AppSizes.iconM;

    if (onRatingUpdate != null) {
      return RatingBar.builder(
        initialRating: rating,
        minRating: 1,
        allowHalfRating: true,
        itemCount: itemCount,
        itemSize: effectiveSize,
        unratedColor: AppColors.starEmpty,
        itemBuilder: (context, _) => const Icon(
          Icons.star_rounded,
          color: AppColors.starFilled,
        ),
        onRatingUpdate: onRatingUpdate!,
      );
    }

    return RatingBarIndicator(
      rating: rating,
      itemCount: itemCount,
      itemSize: effectiveSize,
      unratedColor: AppColors.starEmpty,
      itemBuilder: (context, _) => const Icon(
        Icons.star_rounded,
        color: AppColors.starFilled,
      ),
    );
  }
}
