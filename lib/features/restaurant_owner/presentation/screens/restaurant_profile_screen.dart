import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:tuish_food/core/constants/api_constants.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/glass_scaffold.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/core/widgets/cached_image.dart';
import 'package:tuish_food/features/auth/presentation/providers/auth_provider.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';
import 'package:tuish_food/features/restaurant_owner/domain/entities/subscription_info.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/providers/restaurant_owner_provider.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/providers/subscription_provider.dart';
import 'package:tuish_food/routing/route_paths.dart';

class RestaurantProfileScreen extends ConsumerStatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  ConsumerState<RestaurantProfileScreen> createState() =>
      _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState
    extends ConsumerState<RestaurantProfileScreen> {
  late final Razorpay _razorpay;
  bool _isSubscribing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    setState(() => _isSubscribing = false);

    // Optimistically mark subscription as active in Firestore.
    // The webhook will also do this, but it may be delayed.
    final restaurant = ref.read(myRestaurantProvider).value;
    if (restaurant != null) {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurant.id)
          .update({
        'subscriptionStatus': 'active',
        'isSubscriptionValid': true,
      });
    }

    ref.invalidate(myRestaurantProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Subscription activated!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isSubscribing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message ?? 'Unknown error'}'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // External wallet selected — payment will complete asynchronously
  }

  Future<void> _startSubscription(String restaurantId) async {
    setState(() => _isSubscribing = true);
    try {
      final subscriptionId = await createSubscription(
        ref,
        restaurantId: restaurantId,
      );
      _razorpay.open({
        'key': ApiConstants.razorpayKeyId,
        'subscription_id': subscriptionId,
        'name': 'Tuish Food',
        'description': 'Restaurant Monthly Subscription',
        'theme': {'color': '#FF6B35'},
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubscribing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _cancelSub(String restaurantId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: const Text(
          'Your restaurant will remain visible until the end of the '
          'current billing period. After that, it will be hidden from customers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await cancelSubscription(ref, restaurantId: restaurantId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription will be cancelled at end of period.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantAsync = ref.watch(myRestaurantProvider);

    return restaurantAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: const TuishAppBar(title: 'My Restaurant'),
        body: Center(child: Text('Error: $e')),
      ),
      data: (restaurant) => _buildProfile(context, ref, restaurant),
    );
  }

  Widget _buildProfile(
    BuildContext context,
    WidgetRef ref,
    Restaurant? restaurant,
  ) {
    final name = restaurant?.name ?? 'Your Restaurant';
    final subtitle = restaurant != null
        ? restaurant.cuisineTypes.join(', ')
        : 'Set up your restaurant to get started';

    return GlassScaffold(
      appBar: const TuishAppBar(title: 'My Restaurant'),
      body: ListView(
        padding: EdgeInsets.only(
          left: AppSizes.s24,
          right: AppSizes.s24,
          bottom: AppSizes.s24,
          // Account for glass AppBar overlapping the body
          top: MediaQuery.of(context).padding.top + kToolbarHeight + AppSizes.s16,
        ),
        children: [
          // Restaurant header
          Container(
            padding: AppSizes.paddingAllL,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: AppSizes.borderRadiusL,
            ),
            child: Column(
              children: [
                Builder(builder: (_) {
                  final url = restaurant?.imageUrl ?? '';
                  if (url.isNotEmpty) {
                    return ClipOval(
                      child: CachedImage(
                        imageUrl: url,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    );
                  }
                  return const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.storefront_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  );
                }),
                const SizedBox(height: AppSizes.s12),
                Text(
                  name,
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSizes.s4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.s24),

          // Info cards
          _buildInfoCard(
            icon: Icons.restaurant_menu,
            title: 'Cuisine Types',
            value: restaurant?.cuisineTypes.join(', ') ?? 'Not set',
          ),
          _buildInfoCard(
            icon: Icons.location_on_outlined,
            title: 'Address',
            value: restaurant?.address.fullAddress ?? 'Not set',
          ),
          _buildInfoCard(
            icon: Icons.delivery_dining,
            title: 'Delivery Fee',
            value: '\u20B9${restaurant?.deliveryFee.toStringAsFixed(0) ?? '0'}',
          ),
          _buildInfoCard(
            icon: Icons.shopping_bag_outlined,
            title: 'Minimum Order',
            value:
                '\u20B9${restaurant?.minimumOrderAmount.toStringAsFixed(0) ?? '0'}',
          ),
          _buildInfoCard(
            icon: Icons.timer_outlined,
            title: 'Prep Time',
            value: '${restaurant?.preparationTimeMinutes ?? 0} min',
          ),
          _buildInfoCard(
            icon: Icons.star_rounded,
            title: 'Rating',
            value:
                '${restaurant?.averageRating.toStringAsFixed(1) ?? '0.0'} (${restaurant?.totalRatings ?? 0} reviews)',
          ),
          _buildInfoCard(
            icon: Icons.receipt_long_outlined,
            title: 'Total Orders',
            value: '${restaurant?.totalOrders ?? 0}',
          ),

          const SizedBox(height: AppSizes.s16),

          // Subscription card
          if (restaurant != null) _buildSubscriptionCard(restaurant),

          const SizedBox(height: AppSizes.s24),
          TuishButton.primary(
            label: 'Edit Restaurant Details',
            onPressed: () {
              context.push(RoutePaths.restaurantSetup);
            },
          ),
          const SizedBox(height: AppSizes.s12),
          TuishButton.outlined(
            label: 'Sign Out',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).signOut();
              context.go(RoutePaths.login);
            },
          ),
          const SizedBox(height: AppSizes.s32),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(Restaurant restaurant) {
    final sub = SubscriptionInfo(
      status: restaurant.subscriptionStatus ?? 'none',
      subscriptionId: restaurant.subscriptionId,
      currentEnd: restaurant.subscriptionCurrentEnd,
      graceDeadline: restaurant.subscriptionGraceDeadline,
      isValid: restaurant.isSubscriptionValid,
    );

    Color badgeColor;
    String badgeText;
    String description;
    Widget actionButton;

    if (sub.isActive || sub.isValid) {
      badgeColor = AppColors.success;
      badgeText = 'Active';
      final renewDate = sub.currentEnd != null
          ? DateFormat('MMM dd, yyyy').format(sub.currentEnd!)
          : 'N/A';
      description = 'Next renewal: $renewDate';
      actionButton = TextButton(
        onPressed: () => _cancelSub(restaurant.id),
        child: const Text('Cancel Subscription'),
      );
    } else if (sub.isInGracePeriod) {
      badgeColor = AppColors.warning;
      badgeText = 'Payment Pending';
      final graceDate = sub.graceDeadline != null
          ? DateFormat('MMM dd, yyyy').format(sub.graceDeadline!)
          : 'soon';
      description = 'Your restaurant will be hidden on $graceDate if payment fails.';
      actionButton = TuishButton.primary(
        label: 'Update Payment',
        isLoading: _isSubscribing,
        onPressed: _isSubscribing ? null : () => _startSubscription(restaurant.id),
      );
    } else {
      badgeColor = AppColors.error;
      badgeText = sub.isCancelled ? 'Cancelled' : 'Inactive';
      description = 'Your restaurant is hidden from customers. Subscribe to go live.';
      actionButton = TuishButton.primary(
        label: 'Subscribe Now',
        isLoading: _isSubscribing,
        onPressed: _isSubscribing ? null : () => _startSubscription(restaurant.id),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium_rounded),
                const SizedBox(width: AppSizes.s8),
                Text('Subscription', style: AppTypography.titleSmall),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s8,
                    vertical: AppSizes.s4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: Text(
                    badgeText,
                    style: AppTypography.labelSmall.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s8),
            Text(
              description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.s12),
            SizedBox(width: double.infinity, child: actionButton),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s8),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title, style: AppTypography.labelMedium),
          subtitle: Text(value, style: AppTypography.bodyLarge),
        ),
      ),
    );
  }
}
