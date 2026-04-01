# Notifications

This document describes the push notification system for Tuish Food, including FCM configuration, notification types, deep linking, local notification handling, and user preferences.

---

## FCM Setup

### Firebase Cloud Messaging Configuration

#### Android

```groovy
// android/app/build.gradle
dependencies {
    implementation platform('com.google.firebase:firebase-bom:33.0.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<application>
    <!-- Default notification channel -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_channel_id"
        android:value="tuish_food_default" />

    <!-- Custom notification icon -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_icon"
        android:resource="@drawable/ic_notification" />

    <!-- Notification color -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_color"
        android:resource="@color/notification_color" />
</application>
```

#### iOS

```xml
<!-- ios/Runner/Info.plist -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

Enable Push Notifications capability in Xcode. Upload APNs authentication key to Firebase Console.

#### Flutter Dependencies

```yaml
# pubspec.yaml
dependencies:
  firebase_messaging: ^15.0.0
  flutter_local_notifications: ^17.0.0
```

---

## Initialization

```dart
// lib/core/notifications/notification_service.dart

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return; // User denied notifications
    }

    // 2. Initialize local notifications (for foreground display)
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Already requested above
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 3. Create notification channels (Android)
    await _createNotificationChannels();

    // 4. Get and store FCM token
    await _handleToken();

    // 5. Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveToken);

    // 6. Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 7. Handle background message tap (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 8. Handle terminated state message tap
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }
}
```

---

## Token Management

FCM tokens are stored per-device in the user's Firestore document.

### Token Storage

```dart
Future<void> _handleToken() async {
  final token = await _messaging.getToken();
  if (token != null) {
    await _saveToken(token);
  }
}

Future<void> _saveToken(String token) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  await FirebaseFirestore.instance.doc('users/${user.uid}').update({
    'fcmTokens': FieldValue.arrayUnion([token]),
  });
}
```

### Token Cleanup

```dart
// On logout, remove this device's token
Future<void> removeToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final token = await _messaging.getToken();
  if (token != null) {
    await FirebaseFirestore.instance.doc('users/${user.uid}').update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }

  await _messaging.deleteToken();
}
```

### Multi-Device Support

Users can be signed in on multiple devices. Each device registers its own FCM token. Notifications are sent to all tokens in the `fcmTokens` array.

```typescript
// Cloud Function: Send to all user devices
async function sendNotificationToUser(
  userId: string,
  notification: { title: string; body: string },
  data: Record<string, string>
) {
  const userDoc = await admin.firestore().doc(`users/${userId}`).get();
  const tokens = userDoc.data()?.fcmTokens ?? [];

  if (tokens.length === 0) return;

  const message: admin.messaging.MulticastMessage = {
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: data,
    tokens: tokens,
    android: {
      priority: 'high',
      notification: {
        channelId: getChannelForType(data.type),
        sound: 'default',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        },
      },
    },
  };

  const response = await admin.messaging().sendEachForMulticast(message);

  // Clean up invalid tokens
  const tokensToRemove: string[] = [];
  response.responses.forEach((resp, index) => {
    if (resp.error?.code === 'messaging/invalid-registration-token' ||
        resp.error?.code === 'messaging/registration-token-not-registered') {
      tokensToRemove.push(tokens[index]);
    }
  });

  if (tokensToRemove.length > 0) {
    await admin.firestore().doc(`users/${userId}`).update({
      fcmTokens: admin.firestore.FieldValue.arrayRemove(tokensToRemove),
    });
  }
}
```

---

## Notification Types and Payloads

### Order Status Updates (Customer)

| Status Change | Title | Body | Channel |
| ------------- | ----- | ---- | ------- |
| `placed` | "Order Placed" | "Your order #TF-A1B2 has been placed" | `order_updates` |
| `confirmed` | "Order Confirmed" | "Restaurant has confirmed your order" | `order_updates` |
| `preparing` | "Being Prepared" | "Your food is being prepared" | `order_updates` |
| `readyForPickup` | "Ready for Pickup" | "Your order is ready and waiting for pickup" | `order_updates` |
| `pickedUp` | "On the Way!" | "John is heading to you with your order" | `order_updates` |
| `delivered` | "Delivered!" | "Your order has been delivered. Enjoy!" | `order_updates` |
| `cancelled` | "Order Cancelled" | "Your order #TF-A1B2 has been cancelled" | `order_updates` |

**Payload:**
```json
{
  "notification": {
    "title": "On the Way!",
    "body": "John is heading to you with your order"
  },
  "data": {
    "type": "orderUpdate",
    "orderId": "order_abc123",
    "status": "pickedUp",
    "screen": "/customer/orders/order_abc123/tracking"
  }
}
```

### New Order for Delivery Partner

```json
{
  "notification": {
    "title": "New Delivery Request",
    "body": "Pizza Palace - 1.2 km away - Est. $8.50"
  },
  "data": {
    "type": "newOrder",
    "orderId": "order_abc123",
    "restaurantName": "Pizza Palace",
    "distance": "1.2",
    "estimatedEarning": "850",
    "screen": "/delivery/home",
    "priority": "high"
  }
}
```

### Chat Messages

```json
{
  "notification": {
    "title": "Message from John",
    "body": "I'm at the blue door"
  },
  "data": {
    "type": "chat",
    "chatId": "chat_xyz",
    "orderId": "order_abc123",
    "senderId": "user_john",
    "senderName": "John",
    "screen": "/customer/orders/order_abc123/chat"
  }
}
```

### Promotional Notifications

```json
{
  "notification": {
    "title": "50% Off This Weekend!",
    "body": "Use code WEEKEND50 for 50% off your next order",
    "image": "https://storage.googleapis.com/tuish-food/promos/weekend50.jpg"
  },
  "data": {
    "type": "promotion",
    "promotionId": "promo_xyz",
    "couponCode": "WEEKEND50",
    "screen": "/customer/home"
  }
}
```

### Earnings Updates (Delivery Partner)

```json
{
  "notification": {
    "title": "Delivery Earnings",
    "body": "You earned $12.50 for order #TF-A1B2"
  },
  "data": {
    "type": "earnings",
    "earningsId": "earn_xyz",
    "orderId": "order_abc123",
    "amount": "1250",
    "screen": "/delivery/earnings"
  }
}
```

### Partner Verification

```json
{
  "notification": {
    "title": "Application Approved!",
    "body": "Your delivery partner application has been approved. Start delivering now!"
  },
  "data": {
    "type": "verification",
    "status": "approved",
    "screen": "/delivery/home"
  }
}
```

---

## Notification Channels (Android)

Android notification channels allow users to control notification settings per category at the OS level.

```dart
Future<void> _createNotificationChannels() async {
  final androidPlugin = _localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin == null) return;

  const channels = [
    AndroidNotificationChannel(
      'order_updates',
      'Order Updates',
      description: 'Notifications about your order status',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('order_update'),
    ),
    AndroidNotificationChannel(
      'new_delivery',
      'New Delivery Requests',
      description: 'Alerts when new delivery orders are available',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('new_order'),
    ),
    AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Messages from customers and delivery partners',
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      'promotions',
      'Promotions & Offers',
      description: 'Special deals and promotional offers',
      importance: Importance.defaultImportance,
    ),
    AndroidNotificationChannel(
      'earnings',
      'Earnings & Payouts',
      description: 'Updates about your earnings and payouts',
      importance: Importance.defaultImportance,
    ),
    AndroidNotificationChannel(
      'general',
      'General',
      description: 'General app notifications',
      importance: Importance.defaultImportance,
    ),
  ];

  for (final channel in channels) {
    await androidPlugin.createNotificationChannel(channel);
  }
}
```

---

## Local Notification Handling

### Foreground Notifications

When the app is in the foreground, FCM does not show system notifications by default. We use `flutter_local_notifications` to display them.

```dart
Future<void> _handleForegroundMessage(RemoteMessage message) async {
  final notification = message.notification;
  final data = message.data;

  // Don't show notification if user is on the relevant screen
  if (_shouldSuppressNotification(data)) return;

  // Show local notification
  await _localNotifications.show(
    message.hashCode,
    notification?.title ?? '',
    notification?.body ?? '',
    NotificationDetails(
      android: AndroidNotificationDetails(
        _getChannelForType(data['type'] ?? 'general'),
        _getChannelName(data['type'] ?? 'general'),
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        largeIcon: notification?.android?.imageUrl != null
            ? FilePathAndroidBitmap(notification!.android!.imageUrl!)
            : null,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: jsonEncode(data),
  );
}

bool _shouldSuppressNotification(Map<String, dynamic> data) {
  final currentRoute = _router.routeInformationProvider.value.uri.path;
  final notificationScreen = data['screen'] as String?;

  // Suppress if user is already on the target screen
  return notificationScreen != null && currentRoute == notificationScreen;
}
```

### Background and Terminated Handling

```dart
// This must be a top-level function (not a method)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background messages are automatically displayed as system notifications
  // No additional handling needed unless we want to update local state

  // Store notification in Firestore for in-app notification center
  // (handled by Cloud Function that sends the notification)
}
```

---

## Deep Linking from Notification Tap

### Notification Tap Handler

```dart
void _onNotificationTapped(NotificationResponse response) {
  if (response.payload == null) return;

  final data = jsonDecode(response.payload!) as Map<String, dynamic>;
  _navigateToScreen(data);
}

void _handleMessageOpenedApp(RemoteMessage message) {
  _navigateToScreen(message.data);
}

void _navigateToScreen(Map<String, dynamic> data) {
  final screen = data['screen'] as String?;
  if (screen == null) return;

  // Use GoRouter for navigation
  _router.go(screen);
}
```

### Deep Link Resolution

| Notification Type | Target Screen | GoRouter Path |
| ----------------- | ------------- | ------------- |
| `orderUpdate` | Order Tracking | `/customer/orders/{orderId}/tracking` |
| `newOrder` | Delivery Dashboard | `/delivery/home` |
| `chat` | Chat Screen | `/{role}/orders/{orderId}/chat` or `/{role}/home/active/{orderId}/chat` |
| `promotion` | Customer Home | `/customer/home` |
| `earnings` | Earnings Screen | `/delivery/earnings` |
| `verification` | Appropriate screen based on status | `/delivery/home` or `/verification-pending` |

### Cold Start Navigation

When the app is launched from a terminated state via notification tap:

```dart
// In notification service initialization
Future<void> checkInitialMessage() async {
  final message = await FirebaseMessaging.instance.getInitialMessage();
  if (message != null) {
    // Delay navigation to allow router to initialize
    Future.delayed(const Duration(milliseconds: 500), () {
      _navigateToScreen(message.data);
    });
  }
}
```

---

## Topic Subscriptions (Optional)

Topics allow sending notifications to groups of users without managing individual tokens.

```dart
// Subscribe all customers to promotions
await FirebaseMessaging.instance.subscribeToTopic('promotions_all');

// Subscribe to restaurant-specific updates
await FirebaseMessaging.instance.subscribeToTopic('restaurant_${restaurantId}');

// Unsubscribe
await FirebaseMessaging.instance.unsubscribeFromTopic('promotions_all');
```

### Available Topics

| Topic | Audience | Use Case |
| ----- | -------- | -------- |
| `promotions_all` | All customers | Platform-wide promotions |
| `restaurant_{id}` | Customers who favorited | Restaurant-specific offers |
| `partners_all` | All delivery partners | Partner announcements |
| `system_all` | All users | System maintenance notices |

---

## Notification Preferences

Users can toggle notification categories from their profile settings.

### Firestore Schema

```json
// users/{userId}.notificationPreferences
{
  "orderUpdates": true,
  "promotions": true,
  "chat": true,
  "earnings": true  // delivery partners only
}
```

### Preferences Screen

```
+------------------------------------------+
|  NOTIFICATION SETTINGS                   |
|                                          |
|  Order Updates              [ON]         |
|  Get notified about order status changes |
|                                          |
|  Promotions & Offers        [ON]         |
|  Deals, discounts, and special offers    |
|                                          |
|  Chat Messages              [ON]         |
|  Messages from delivery partners         |
|                                          |
|  Earnings Updates           [ON]         |
|  Delivery earnings and payout updates    |
+------------------------------------------+
```

### Server-Side Preference Check

Before sending a notification, the Cloud Function checks the user's preferences:

```typescript
async function shouldSendNotification(
  userId: string,
  type: string
): Promise<boolean> {
  const userDoc = await admin.firestore().doc(`users/${userId}`).get();
  const preferences = userDoc.data()?.notificationPreferences ?? {};

  const preferenceMap: Record<string, string> = {
    'orderUpdate': 'orderUpdates',
    'newOrder': 'orderUpdates',    // Partners always get order notifications
    'chat': 'chat',
    'promotion': 'promotions',
    'earnings': 'earnings',
  };

  const preferenceKey = preferenceMap[type];
  if (!preferenceKey) return true; // Unknown type, send by default

  return preferences[preferenceKey] !== false; // Default to true
}
```

---

## Cloud Function Notification Triggers

### Order Status Change Notification

```typescript
// Called from onOrderUpdated
async function sendOrderStatusNotification(
  orderId: string,
  oldStatus: string,
  newStatus: string,
  order: any
) {
  const notificationMap: Record<string, { title: string; body: string; recipient: string }> = {
    'confirmed': {
      title: 'Order Confirmed',
      body: `${order.restaurantName} has confirmed your order`,
      recipient: order.customerId,
    },
    'preparing': {
      title: 'Being Prepared',
      body: 'Your food is being prepared',
      recipient: order.customerId,
    },
    'readyForPickup': {
      title: 'Ready for Pickup',
      body: 'Your order is ready and waiting for pickup',
      recipient: order.customerId,
    },
    'pickedUp': {
      title: 'On the Way!',
      body: `${order.deliveryPartnerName} is heading to you with your order`,
      recipient: order.customerId,
    },
    'delivered': {
      title: 'Delivered!',
      body: 'Your order has been delivered. Enjoy!',
      recipient: order.customerId,
    },
    'cancelled': {
      title: 'Order Cancelled',
      body: `Your order #${order.orderNumber} has been cancelled`,
      recipient: order.customerId,
    },
  };

  const config = notificationMap[newStatus];
  if (!config) return;

  // Check preference
  if (!(await shouldSendNotification(config.recipient, 'orderUpdate'))) return;

  // Send push notification
  await sendNotificationToUser(config.recipient, {
    title: config.title,
    body: config.body,
  }, {
    type: 'orderUpdate',
    orderId: orderId,
    status: newStatus,
    screen: `/customer/orders/${orderId}/tracking`,
  });

  // Store in notifications collection for in-app notification center
  await admin.firestore().collection('notifications').add({
    userId: config.recipient,
    title: config.title,
    body: config.body,
    type: 'orderUpdate',
    data: { orderId, status: newStatus },
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}
```

---

## In-App Notification Center

In addition to push notifications, all notifications are stored in Firestore and displayed in an in-app notification center.

### Notification Feed Provider

```dart
@riverpod
Stream<List<NotificationEntity>> notificationFeed(NotificationFeedRef ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
}
```

### Mark as Read

```dart
Future<void> markNotificationAsRead(String notificationId) async {
  await FirebaseFirestore.instance
      .doc('notifications/$notificationId')
      .update({'isRead': true});
}

Future<void> markAllNotificationsAsRead() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final batch = FirebaseFirestore.instance.batch();
  final unread = await FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: user.uid)
      .where('isRead', isEqualTo: false)
      .get();

  for (final doc in unread.docs) {
    batch.update(doc.reference, {'isRead': true});
  }

  await batch.commit();
}
```
