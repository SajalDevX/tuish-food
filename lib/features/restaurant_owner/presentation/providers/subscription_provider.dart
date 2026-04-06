import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/features/restaurant_owner/domain/entities/subscription_info.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/providers/restaurant_owner_provider.dart';

/// Derives the subscription status from the current owner's restaurant data.
final mySubscriptionProvider = Provider.autoDispose<SubscriptionInfo>((ref) {
  final restaurantAsync = ref.watch(myRestaurantProvider);
  final restaurant = restaurantAsync.value;

  if (restaurant == null) return SubscriptionInfo.none();

  return SubscriptionInfo(
    status: restaurant.subscriptionStatus ?? 'none',
    subscriptionId: restaurant.subscriptionId,
    currentEnd: restaurant.subscriptionCurrentEnd,
    graceDeadline: restaurant.subscriptionGraceDeadline,
    isValid: restaurant.isSubscriptionValid,
  );
});

/// Creates a Razorpay subscription for a restaurant via Cloud Function.
/// Returns the subscription ID to use with the Razorpay SDK.
Future<String> createSubscription(
  WidgetRef ref, {
  required String restaurantId,
}) async {
  final callable =
      FirebaseFunctions.instance.httpsCallable('createSubscription');
  final result = await callable.call<Map<String, dynamic>>({
    'restaurantId': restaurantId,
  });
  ref.invalidate(myRestaurantProvider);
  return result.data['subscriptionId'] as String;
}

/// Cancels a restaurant's subscription at the end of the current billing cycle.
Future<void> cancelSubscription(
  WidgetRef ref, {
  required String restaurantId,
}) async {
  final callable =
      FirebaseFunctions.instance.httpsCallable('cancelSubscription');
  await callable.call<Map<String, dynamic>>({
    'restaurantId': restaurantId,
  });
  ref.invalidate(myRestaurantProvider);
}
