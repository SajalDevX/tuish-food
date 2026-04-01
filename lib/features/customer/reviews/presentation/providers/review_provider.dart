import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/features/customer/reviews/data/datasources/review_remote_datasource.dart';
import 'package:tuish_food/features/customer/reviews/data/repositories/review_repository_impl.dart';
import 'package:tuish_food/features/customer/reviews/domain/entities/review.dart';
import 'package:tuish_food/features/customer/reviews/domain/repositories/review_repository.dart';
import 'package:tuish_food/injection_container.dart';

// Data source
final reviewRemoteDataSourceProvider =
    Provider<ReviewRemoteDataSource>((ref) {
  return ReviewRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
  );
});

// Repository
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(
    remoteDataSource: ref.watch(reviewRemoteDataSourceProvider),
  );
});

// Restaurant reviews
final restaurantReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, restaurantId) async {
  final repository = ref.watch(reviewRepositoryProvider);
  final result = await repository.getReviews('restaurant', restaurantId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (reviews) => reviews,
  );
});

// Delivery partner reviews
final deliveryPartnerReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, partnerId) async {
  final repository = ref.watch(reviewRepositoryProvider);
  final result =
      await repository.getReviews('deliveryPartner', partnerId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (reviews) => reviews,
  );
});

// Submit review notifier
final submitReviewProvider =
    NotifierProvider<SubmitReviewNotifier, AsyncValue<void>>(
        SubmitReviewNotifier.new);

class SubmitReviewNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  ReviewRepository get _repository => ref.watch(reviewRepositoryProvider);

  Future<bool> submitReview(Review review) async {
    state = const AsyncLoading();
    final result = await _repository.submitReview(review);
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }
}
