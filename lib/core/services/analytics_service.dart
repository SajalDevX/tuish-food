import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper around [FirebaseAnalytics] that provides a consistent
/// logging interface and silently swallows errors in non-debug builds so
/// analytics failures never crash the app.
class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  /// A [NavigatorObserver] that can be added to your router to automatically
  /// log screen views.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  /// Logs a custom event with optional [parameters].
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('AnalyticsService: failed to log event "$name" -- $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Screen views
  // ---------------------------------------------------------------------------

  /// Logs a screen-view event.
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      debugPrint(
        'AnalyticsService: failed to log screen view "$screenName" -- $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // User properties
  // ---------------------------------------------------------------------------

  /// Sets the Firebase Analytics user ID.
  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
    } catch (e) {
      debugPrint('AnalyticsService: failed to set user ID -- $e');
    }
  }

  /// Sets a custom user property.
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint(
        'AnalyticsService: failed to set user property "$name" -- $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Pre-defined event helpers (food-delivery domain)
  // ---------------------------------------------------------------------------

  /// Logs when a user adds an item to the cart.
  Future<void> logAddToCart({
    required String itemId,
    required String itemName,
    required double price,
    int quantity = 1,
  }) async {
    await logEvent(
      name: 'add_to_cart',
      parameters: {
        'item_id': itemId,
        'item_name': itemName,
        'price': price,
        'quantity': quantity,
      },
    );
  }

  /// Logs when a user places an order.
  Future<void> logPurchase({
    required String orderId,
    required double total,
    required int itemCount,
    String currency = 'INR',
  }) async {
    await logEvent(
      name: 'purchase',
      parameters: {
        'transaction_id': orderId,
        'value': total,
        'currency': currency,
        'items_count': itemCount,
      },
    );
  }

  /// Logs when a user performs a search.
  Future<void> logSearch(String query) async {
    await logEvent(
      name: 'search',
      parameters: {'search_term': query},
    );
  }

  /// Resets the analytics data (e.g. on sign-out).
  Future<void> resetAnalyticsData() async {
    try {
      await _analytics.resetAnalyticsData();
    } catch (e) {
      debugPrint('AnalyticsService: failed to reset analytics data -- $e');
    }
  }
}

// -----------------------------------------------------------------------------
// Riverpod provider
// -----------------------------------------------------------------------------

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
