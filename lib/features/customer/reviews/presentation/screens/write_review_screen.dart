import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/rating_bar.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/core/widgets/tuish_text_field.dart';
import 'package:tuish_food/features/customer/orders/presentation/providers/order_provider.dart';
import 'package:tuish_food/features/customer/reviews/domain/entities/review.dart';
import 'package:tuish_food/features/customer/reviews/presentation/providers/review_provider.dart';
import 'package:tuish_food/injection_container.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  const WriteReviewScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _commentController = TextEditingController();
  double _overallRating = 0;
  double _foodRating = 0;
  double _packagingRating = 0;
  double _valueRating = 0;
  bool _isSubmitting = false;

  // For delivery partner review
  bool _showDriverReview = false;
  double _driverOverallRating = 0;
  double _punctualityRating = 0;
  double _courtesyRating = 0;
  final _driverCommentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    _driverCommentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: const TuishAppBar(title: 'Write Review'),
      body: orderAsync.when(
        data: (order) {
          return SingleChildScrollView(
            padding: AppSizes.paddingAllM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant info
                Text(
                  'Rate ${order.restaurantName ?? 'Restaurant'}',
                  style: AppTypography.headlineSmall,
                ),
                const SizedBox(height: AppSizes.s8),
                Text(
                  'Order #${order.orderNumber}',
                  style: AppTypography.bodySmall,
                ),

                const SizedBox(height: AppSizes.s24),

                // Overall rating
                _buildRatingSection(
                  'Overall Rating',
                  _overallRating,
                  (val) => setState(() => _overallRating = val),
                ),

                const SizedBox(height: AppSizes.s20),

                // Sub-ratings for restaurant
                _buildRatingSection(
                  'Food Quality',
                  _foodRating,
                  (val) => setState(() => _foodRating = val),
                  size: 28,
                ),
                const SizedBox(height: AppSizes.s16),
                _buildRatingSection(
                  'Packaging',
                  _packagingRating,
                  (val) => setState(() => _packagingRating = val),
                  size: 28,
                ),
                const SizedBox(height: AppSizes.s16),
                _buildRatingSection(
                  'Value for Money',
                  _valueRating,
                  (val) => setState(() => _valueRating = val),
                  size: 28,
                ),

                const SizedBox(height: AppSizes.s20),

                // Comment
                TuishTextField(
                  label: 'Comment (optional)',
                  hint: 'Share your experience...',
                  controller: _commentController,
                  maxLines: 4,
                ),

                // Driver review section
                if (order.deliveryPartnerId != null) ...[
                  const SizedBox(height: AppSizes.s24),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: AppSizes.s16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rate Delivery Partner',
                        style: AppTypography.titleMedium,
                      ),
                      Switch(
                        value: _showDriverReview,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) =>
                            setState(() => _showDriverReview = val),
                      ),
                    ],
                  ),

                  if (_showDriverReview) ...[
                    const SizedBox(height: AppSizes.s16),

                    if (order.deliveryPartnerName != null)
                      Text(
                        order.deliveryPartnerName!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),

                    const SizedBox(height: AppSizes.s16),

                    _buildRatingSection(
                      'Overall',
                      _driverOverallRating,
                      (val) =>
                          setState(() => _driverOverallRating = val),
                    ),
                    const SizedBox(height: AppSizes.s16),
                    _buildRatingSection(
                      'Punctuality',
                      _punctualityRating,
                      (val) =>
                          setState(() => _punctualityRating = val),
                      size: 28,
                    ),
                    const SizedBox(height: AppSizes.s16),
                    _buildRatingSection(
                      'Courtesy',
                      _courtesyRating,
                      (val) =>
                          setState(() => _courtesyRating = val),
                      size: 28,
                    ),

                    const SizedBox(height: AppSizes.s16),

                    TuishTextField(
                      label: 'Comment for driver (optional)',
                      hint: 'How was the delivery?',
                      controller: _driverCommentController,
                      maxLines: 3,
                    ),
                  ],
                ],

                const SizedBox(height: AppSizes.s32),

                // Submit button
                TuishButton.primary(
                  label: 'Submit Review',
                  isLoading: _isSubmitting,
                  onPressed: _overallRating > 0
                      ? () => _submitReview(order.restaurantId,
                          order.deliveryPartnerId)
                      : null,
                ),

                const SizedBox(height: AppSizes.s32),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Text(
            error.toString(),
            style: AppTypography.bodyMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection(
    String label,
    double rating,
    ValueChanged<double> onUpdate, {
    double size = 36,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelLarge),
        const SizedBox(height: AppSizes.s8),
        TuishRatingBar(
          rating: rating,
          size: size,
          onRatingUpdate: onUpdate,
        ),
      ],
    );
  }

  Future<void> _submitReview(
      String restaurantId, String? deliveryPartnerId) async {
    setState(() => _isSubmitting = true);

    final currentUser = ref.read(currentUserProvider);
    final reviewNotifier = ref.read(submitReviewProvider.notifier);
    const uuid = Uuid();

    // Submit restaurant review
    final restaurantReview = Review(
      id: uuid.v4(),
      orderId: widget.orderId,
      reviewerId: currentUser?.uid ?? '',
      reviewerName: currentUser?.displayName,
      reviewerPhotoUrl: currentUser?.photoURL,
      targetType: 'restaurant',
      targetId: restaurantId,
      rating: _overallRating,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      foodRating: _foodRating > 0 ? _foodRating : null,
      packagingRating: _packagingRating > 0 ? _packagingRating : null,
      valueRating: _valueRating > 0 ? _valueRating : null,
      createdAt: DateTime.now(),
    );

    final restaurantSuccess =
        await reviewNotifier.submitReview(restaurantReview);

    // Submit delivery partner review if applicable
    bool driverSuccess = true;
    if (_showDriverReview &&
        deliveryPartnerId != null &&
        _driverOverallRating > 0) {
      final driverReview = Review(
        id: uuid.v4(),
        orderId: widget.orderId,
        reviewerId: currentUser?.uid ?? '',
        reviewerName: currentUser?.displayName,
        reviewerPhotoUrl: currentUser?.photoURL,
        targetType: 'deliveryPartner',
        targetId: deliveryPartnerId,
        rating: _driverOverallRating,
        comment: _driverCommentController.text.trim().isEmpty
            ? null
            : _driverCommentController.text.trim(),
        punctualityRating:
            _punctualityRating > 0 ? _punctualityRating : null,
        courtesyRating:
            _courtesyRating > 0 ? _courtesyRating : null,
        createdAt: DateTime.now(),
      );
      driverSuccess = await reviewNotifier.submitReview(driverReview);
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (restaurantSuccess && driverSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit review. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
