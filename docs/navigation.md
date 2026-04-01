# Navigation

This document describes the routing and navigation architecture of Tuish Food using GoRouter, including the route tree, shell routes, role-based redirects, guards, and deep linking.

---

## GoRouter Overview

Tuish Food uses `go_router` for declarative, URL-based routing. GoRouter integrates with Riverpod for reactive redirects based on authentication and role state.

### Setup

```yaml
# pubspec.yaml
dependencies:
  go_router: ^14.0.0
```

### App Configuration

```dart
// app.dart
class TuishFoodApp extends ConsumerWidget {
  const TuishFoodApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Tuish Food',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
```

---

## Route Tree

```
/
+-- /splash                          SplashScreen
+-- /login                           LoginScreen
+-- /signup                          SignupScreen
+-- /otp-verification                OtpVerificationScreen
+-- /partner-registration            PartnerRegistrationScreen
+-- /verification-pending            VerificationPendingScreen
|
+-- /customer                        CustomerShell (StatefulShellRoute)
|     +-- /customer/home             HomeScreen
|     |     +-- /customer/home/search               SearchScreen
|     |     +-- /customer/home/category/:id          CategoryRestaurantsScreen
|     |     +-- /customer/home/restaurant/:id        RestaurantDetailScreen
|     |           +-- /customer/home/restaurant/:id/reviews  ReviewsListScreen
|     +-- /customer/orders           OrderHistoryScreen
|     |     +-- /customer/orders/:id                 OrderDetailScreen
|     |     +-- /customer/orders/:id/tracking        OrderTrackingScreen
|     |     +-- /customer/orders/:id/chat            ChatScreen
|     |     +-- /customer/orders/:id/review          ReviewScreen
|     +-- /customer/cart             CartScreen
|     |     +-- /customer/cart/checkout              CheckoutScreen
|     |     +-- /customer/cart/checkout/address       AddressSelectionScreen
|     |     +-- /customer/cart/checkout/payment       PaymentMethodScreen
|     |     +-- /customer/cart/checkout/confirmation  OrderConfirmationScreen
|     +-- /customer/profile          ProfileScreen
|           +-- /customer/profile/edit               EditProfileScreen
|           +-- /customer/profile/addresses           ManageAddressesScreen
|           |     +-- /customer/profile/addresses/add     AddAddressScreen
|           |     +-- /customer/profile/addresses/:id     EditAddressScreen
|           +-- /customer/profile/favorites           FavoritesScreen
|           +-- /customer/profile/notifications       NotificationSettingsScreen
|
+-- /delivery                        DeliveryShell (StatefulShellRoute)
|     +-- /delivery/home             DeliveryDashboardScreen
|     |     +-- /delivery/home/active/:id            ActiveDeliveryScreen
|     |     +-- /delivery/home/active/:id/navigation NavigationScreen
|     |     +-- /delivery/home/active/:id/detail     DeliveryOrderDetailScreen
|     |     +-- /delivery/home/active/:id/chat       ChatScreen
|     +-- /delivery/orders           DeliveryHistoryScreen
|     |     +-- /delivery/orders/:id                 DeliveryDetailScreen
|     +-- /delivery/earnings         EarningsScreen
|     |     +-- /delivery/earnings/payouts           PayoutHistoryScreen
|     +-- /delivery/profile          DeliveryProfileScreen
|           +-- /delivery/profile/vehicle            VehicleInfoScreen
|           +-- /delivery/profile/documents           DocumentsScreen
|           +-- /delivery/profile/ratings             RatingHistoryScreen
|
+-- /admin                           AdminShell (ShellRoute with Drawer)
      +-- /admin/dashboard           AdminDashboardScreen
      +-- /admin/restaurants         RestaurantListScreen
      |     +-- /admin/restaurants/add               AddRestaurantScreen
      |     +-- /admin/restaurants/:id               RestaurantDetailScreen
      |     +-- /admin/restaurants/:id/edit           EditRestaurantScreen
      |     +-- /admin/restaurants/:id/menu           MenuManagementScreen
      |           +-- /admin/restaurants/:id/menu/item/add     AddMenuItemScreen
      |           +-- /admin/restaurants/:id/menu/item/:itemId EditMenuItemScreen
      +-- /admin/users               UserListScreen
      |     +-- /admin/users/:id                     UserDetailScreen
      +-- /admin/partners            PartnerListScreen
      |     +-- /admin/partners/queue                VerificationQueueScreen
      |     +-- /admin/partners/:id                  PartnerDetailScreen
      +-- /admin/orders              OrderManagementScreen
      |     +-- /admin/orders/:id                    AdminOrderDetailScreen
      +-- /admin/promotions          PromotionListScreen
      |     +-- /admin/promotions/add                AddPromotionScreen
      |     +-- /admin/promotions/:id                PromotionDetailScreen
      |     +-- /admin/promotions/:id/edit           EditPromotionScreen
      +-- /admin/settings            AppSettingsScreen
```

---

## Shell Routes

Each user role has a dedicated `StatefulShellRoute` that provides persistent bottom navigation (or drawer for admin).

### Customer Shell

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) {
    return CustomerShell(navigationShell: navigationShell);
  },
  branches: [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/customer/home',
          builder: (context, state) => const HomeScreen(),
          routes: [/* nested routes */],
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/customer/orders',
          builder: (context, state) => const OrderHistoryScreen(),
          routes: [/* nested routes */],
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/customer/cart',
          builder: (context, state) => const CartScreen(),
          routes: [/* nested routes */],
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/customer/profile',
          builder: (context, state) => const ProfileScreen(),
          routes: [/* nested routes */],
        ),
      ],
    ),
  ],
)
```

**Bottom Navigation Items:**

| Index | Label | Icon | Route |
| ----- | ----- | ---- | ----- |
| 0 | Home | `Icons.home_rounded` | `/customer/home` |
| 1 | Orders | `Icons.receipt_long_rounded` | `/customer/orders` |
| 2 | Cart | `Icons.shopping_cart_rounded` (with badge) | `/customer/cart` |
| 3 | Profile | `Icons.person_rounded` | `/customer/profile` |

### Delivery Shell

**Bottom Navigation Items:**

| Index | Label | Icon | Route |
| ----- | ----- | ---- | ----- |
| 0 | Home | `Icons.home_rounded` | `/delivery/home` |
| 1 | Orders | `Icons.receipt_long_rounded` | `/delivery/orders` |
| 2 | Earnings | `Icons.account_balance_wallet_rounded` | `/delivery/earnings` |
| 3 | Profile | `Icons.person_rounded` | `/delivery/profile` |

### Admin Shell

Uses a `Scaffold` with a `Drawer` (or permanent side navigation on wider screens):

**Drawer Items:**

| Label | Icon | Route |
| ----- | ---- | ----- |
| Dashboard | `Icons.dashboard_rounded` | `/admin/dashboard` |
| Restaurants | `Icons.restaurant_rounded` | `/admin/restaurants` |
| Users | `Icons.people_rounded` | `/admin/users` |
| Partners | `Icons.delivery_dining_rounded` | `/admin/partners` |
| Orders | `Icons.receipt_long_rounded` | `/admin/orders` |
| Promotions | `Icons.local_offer_rounded` | `/admin/promotions` |
| Settings | `Icons.settings_rounded` | `/admin/settings` |

---

## Role-Based Redirect Logic

The router uses `redirect` to enforce authentication and role-based access.

```dart
@riverpod
GoRouter router(RouterRef ref) {
  final authState = ref.watch(authStateProvider);
  final userRole = ref.watch(userRoleProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authStateProvider.stream),
    ),
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final role = userRole.valueOrNull;
      final currentPath = state.matchedLocation;

      // Public routes that don't require auth
      final publicRoutes = ['/login', '/signup', '/otp-verification', '/splash'];
      final isPublicRoute = publicRoutes.contains(currentPath);

      // Not logged in
      if (!isLoggedIn) {
        return isPublicRoute ? null : '/login';
      }

      // Logged in but on public route -> redirect to appropriate shell
      if (isPublicRoute && currentPath != '/splash') {
        return _getHomeForRole(role);
      }

      // Role-based access control
      if (currentPath.startsWith('/customer') && role != UserRole.customer) {
        return _getHomeForRole(role);
      }
      if (currentPath.startsWith('/delivery') && role != UserRole.deliveryPartner) {
        return _getHomeForRole(role);
      }
      if (currentPath.startsWith('/admin') && role != UserRole.admin) {
        return _getHomeForRole(role);
      }

      // Delivery partner verification check
      if (role == UserRole.deliveryPartner) {
        final verificationStatus = ref.read(verificationStatusProvider).valueOrNull;
        if (verificationStatus == 'pending' && currentPath != '/verification-pending') {
          return '/verification-pending';
        }
        if (verificationStatus == 'rejected' && currentPath != '/partner-registration') {
          return '/partner-registration';
        }
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      // ... shell routes ...
    ],
  );
}

String? _getHomeForRole(UserRole? role) {
  switch (role) {
    case UserRole.customer:
      return '/customer/home';
    case UserRole.deliveryPartner:
      return '/delivery/home';
    case UserRole.admin:
      return '/admin/dashboard';
    case null:
      return '/login';
  }
}
```

---

## Redirect Flow Diagram

```
GoRouter evaluates redirect
    |
    v
Is user authenticated?
    |
    +-- No
    |     |
    |     +-- On public route? --> Allow (return null)
    |     +-- On protected route? --> Redirect to /login
    |
    +-- Yes
          |
          +-- On public route (login/signup)?
          |     |
          |     v
          |   Redirect to role-appropriate home
          |
          +-- On protected route
                |
                v
          Does route prefix match user role?
                |
                +-- No --> Redirect to role-appropriate home
                |
                +-- Yes
                      |
                      v
                Is delivery partner with pending verification?
                      |
                      +-- Yes --> /verification-pending
                      +-- No --> Allow (return null)
```

---

## Deep Linking from Notifications

When a user taps a notification, the app navigates to a specific screen.

### Notification Payload

```json
{
  "notification": {
    "title": "Your order is on the way!",
    "body": "John is heading to you with your order."
  },
  "data": {
    "type": "orderUpdate",
    "orderId": "order_abc123",
    "screen": "/customer/orders/order_abc123/tracking"
  }
}
```

### Handling in Flutter

```dart
// On notification tap (app in background or terminated)
FirebaseMessaging.instance.getInitialMessage().then((message) {
  if (message != null) {
    _handleNotificationNavigation(message);
  }
});

FirebaseMessaging.onMessageOpenedApp.listen((message) {
  _handleNotificationNavigation(message);
});

void _handleNotificationNavigation(RemoteMessage message) {
  final screen = message.data['screen'] as String?;
  if (screen != null) {
    // GoRouter handles the navigation
    ref.read(routerProvider).go(screen);
  }
}
```

### Deep Link Paths by Notification Type

| Notification Type | Target Screen | Path |
| ----------------- | ------------- | ---- |
| Order update (customer) | Order Tracking | `/customer/orders/{orderId}/tracking` |
| New order (partner) | Active Delivery | `/delivery/home/active/{orderId}` |
| Chat message | Chat Screen | `/customer/orders/{orderId}/chat` or `/delivery/home/active/{orderId}/chat` |
| Partner approved | Delivery Home | `/delivery/home` |
| Promotion | Home (with promo) | `/customer/home` |
| Earnings update | Earnings | `/delivery/earnings` |

---

## Route Guards

### Auth Guard

Ensures the user is authenticated. Handled by the main redirect function.

### Role Guard

Ensures the user has the correct role for the route. Handled by the main redirect function via path prefix matching.

### Onboarding Guard

Checks if a new customer has completed initial setup (e.g., setting delivery address):

```dart
// Inside the customer shell redirect
if (role == UserRole.customer) {
  final hasAddress = ref.read(userAddressesProvider).valueOrNull?.isNotEmpty ?? false;
  final isOnboardingRoute = currentPath == '/customer/profile/addresses/add';

  if (!hasAddress && !isOnboardingRoute) {
    // First-time user needs to add an address
    return '/customer/profile/addresses/add?onboarding=true';
  }
}
```

### Verification Guard

Prevents unapproved delivery partners from accessing the delivery shell:

```dart
if (role == UserRole.deliveryPartner) {
  final status = ref.read(verificationStatusProvider).valueOrNull;

  if (status == 'pending') return '/verification-pending';
  if (status == 'rejected') return '/partner-registration';
  // 'approved' -> allow through
}
```

---

## Named Routes and Path Constants

All route paths are defined as constants to prevent typos:

```dart
abstract class AppRoutes {
  // Public
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const otpVerification = '/otp-verification';
  static const partnerRegistration = '/partner-registration';
  static const verificationPending = '/verification-pending';

  // Customer
  static const customerHome = '/customer/home';
  static const customerSearch = '/customer/home/search';
  static String customerCategory(String id) => '/customer/home/category/$id';
  static String customerRestaurant(String id) => '/customer/home/restaurant/$id';
  static String customerRestaurantReviews(String id) =>
      '/customer/home/restaurant/$id/reviews';
  static const customerOrders = '/customer/orders';
  static String customerOrderDetail(String id) => '/customer/orders/$id';
  static String customerOrderTracking(String id) => '/customer/orders/$id/tracking';
  static String customerOrderChat(String id) => '/customer/orders/$id/chat';
  static String customerOrderReview(String id) => '/customer/orders/$id/review';
  static const customerCart = '/customer/cart';
  static const customerCheckout = '/customer/cart/checkout';
  static const customerProfile = '/customer/profile';
  static const customerEditProfile = '/customer/profile/edit';
  static const customerAddresses = '/customer/profile/addresses';
  static const customerFavorites = '/customer/profile/favorites';

  // Delivery
  static const deliveryHome = '/delivery/home';
  static String deliveryActive(String id) => '/delivery/home/active/$id';
  static String deliveryNavigation(String id) => '/delivery/home/active/$id/navigation';
  static const deliveryOrders = '/delivery/orders';
  static const deliveryEarnings = '/delivery/earnings';
  static const deliveryProfile = '/delivery/profile';

  // Admin
  static const adminDashboard = '/admin/dashboard';
  static const adminRestaurants = '/admin/restaurants';
  static const adminUsers = '/admin/users';
  static const adminPartners = '/admin/partners';
  static const adminPartnerQueue = '/admin/partners/queue';
  static const adminOrders = '/admin/orders';
  static const adminPromotions = '/admin/promotions';
  static const adminSettings = '/admin/settings';
}
```

---

## GoRouter + Riverpod Integration

### RefreshListenable

GoRouter's `refreshListenable` triggers a re-evaluation of redirects when auth state changes:

```dart
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

This ensures that when the user logs in, logs out, or has their role changed, the router automatically re-evaluates and navigates to the correct location.

### Accessing Router from Providers

```dart
// Navigate from a provider (e.g., after successful order placement)
ref.read(routerProvider).go(
  AppRoutes.customerOrderTracking(orderId),
);
```

---

## Page Transitions

Custom page transitions for a polished navigation experience:

```dart
CustomTransitionPage<void> buildPageWithSlideTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        )),
        child: child,
      );
    },
  );
}

// Bottom sheet routes (item detail, address selection)
CustomTransitionPage<void> buildPageWithBottomSheetTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      );
    },
  );
}
```
