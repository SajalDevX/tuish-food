import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Top-level handler for background FCM messages.
///
/// Must be a top-level function (not a closure or instance method) so the
/// Flutter engine can look it up when the app is terminated.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    'NotificationService: background message received -- ${message.messageId}',
  );
}

/// Manages Firebase Cloud Messaging tokens, permissions, and local
/// notification display.
class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Android notification channel
  // ---------------------------------------------------------------------------

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'tuish_food_high_importance',
    'Tuish Food Notifications',
    description: 'High-importance notifications for Tuish Food orders & updates',
    importance: Importance.high,
  );

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Sets up FCM background handler, local notifications plugin, and the
  /// high-importance Android channel.  Safe to call more than once.
  Future<void> init() async {
    if (_initialized) return;

    // Register the background handler.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Create the Android notification channel.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Initialize the local-notifications plugin.
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Listen to foreground messages and display them as local notifications.
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    _initialized = true;
    debugPrint('NotificationService: initialized');
  }

  // ---------------------------------------------------------------------------
  // Token management
  // ---------------------------------------------------------------------------

  /// Returns the current FCM registration token, or `null` if unavailable.
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('NotificationService: failed to get token -- $e');
      return null;
    }
  }

  /// Stream that emits a new token whenever FCM refreshes it.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  /// Requests notification permissions from the user.
  ///
  /// Returns the resulting [NotificationSettings].
  Future<NotificationSettings> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint(
      'NotificationService: permission status -- '
      '${settings.authorizationStatus}',
    );
    return settings;
  }

  // ---------------------------------------------------------------------------
  // Foreground message handling
  // ---------------------------------------------------------------------------

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final android = notification.android;

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['route'],
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint(
      'NotificationService: notification tapped -- payload=${response.payload}',
    );
    // Navigation based on the payload can be handled at the app level by
    // listening to FirebaseMessaging.onMessageOpenedApp or by providing a
    // callback during init.
  }

  // ---------------------------------------------------------------------------
  // App-open / terminated messages
  // ---------------------------------------------------------------------------

  /// Stream of messages received while the app is in the foreground.
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  /// Stream of notification taps that opened the app from background.
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  /// Returns the [RemoteMessage] that launched the app from a terminated
  /// state, if any.
  Future<RemoteMessage?> getInitialMessage() =>
      _messaging.getInitialMessage();
}

// -----------------------------------------------------------------------------
// Riverpod provider
// -----------------------------------------------------------------------------

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
