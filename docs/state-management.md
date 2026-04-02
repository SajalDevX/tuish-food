# State Management

This document describes the state management strategy for Tuish Food using Riverpod 2.x, including provider patterns, architecture decisions, code examples, and testing approaches.

---

## Why Riverpod over BLoC

| Criteria | Riverpod | BLoC |
| -------- | -------- | ---- |
| **Compile-time safety** | Providers are checked at compile time; no runtime `ProviderNotFoundException` | Requires `BlocProvider` in widget tree; runtime errors if missing |
| **Boilerplate** | Minimal with `@riverpod` code generation | Requires Event classes, State classes, Bloc class, BlocProvider, BlocBuilder |
| **BuildContext dependency** | Providers are independent of widget tree; accessible anywhere via `ref` | Requires `BuildContext` to access (`context.read<Bloc>()`) |
| **Stream support** | Native `StreamProvider` with automatic lifecycle management | Built around streams but requires manual subscription management |
| **Testing** | `ProviderScope` overrides make dependency injection trivial | Requires `BlocProvider` setup or mock injection |
| **Scoped overrides** | First-class support for providing different implementations per subtree | Possible but more complex |
| **Dependency tracking** | Automatic: `ref.watch()` creates reactive dependency graph | Manual: must explicitly add events or listen to other blocs |
| **Code generation** | `@riverpod` annotation generates providers from plain functions/classes | `freezed` + `bloc` generators for events and states |

---

## Riverpod 2.x with Code Generation

Tuish Food uses the `@riverpod` annotation (from `riverpod_annotation` package) for code generation. This eliminates manual provider declarations.

### Setup

```yaml
# pubspec.yaml
dependencies:
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

dev_dependencies:
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.0
  riverpod_lint: ^2.3.0
```

### Code Generation Command

```bash
dart run build_runner build --delete-conflicting-outputs

# Or watch mode during development
dart run build_runner watch --delete-conflicting-outputs
```

---

## Provider Types

| Provider Type | Use Case | Example |
| ------------- | -------- | ------- |
| `Provider` | Synchronous computed values, repository instances | `restaurantRepositoryProvider` |
| `FutureProvider` | One-time async data fetch | `userProfileProvider` |
| `StreamProvider` | Real-time data (Firestore snapshots) | `orderStatusProvider` |
| `NotifierProvider` | Mutable state with methods | `cartNotifierProvider` |
| `AsyncNotifierProvider` | Async mutable state with methods | `checkoutNotifierProvider` |

---

## Provider Hierarchy

```
                        Core Providers
                    +------------------+
                    | firebaseAuth     |
                    | firestore        |
                    | firebaseStorage  |
                    | firebaseMessaging|
                    +------------------+
                            |
                    +------------------+
                    |  Auth Providers   |
                    +------------------+
                    | authStateProvider |  <-- StreamProvider (auth state changes)
                    | currentUserProv. |  <-- Provider (current Firebase User)
                    | userRoleProvider |  <-- FutureProvider (custom claims)
                    +------------------+
                            |
              +-------------+-------------+
              |             |             |
    +---------+--+  +------+------+  +---+--------+
    | Repository  |  | Repository  |  | Repository |
    | Providers   |  | Providers   |  | Providers  |
    +------------+  +------------+  +------------+
    | userRepo    |  | restaurant  |  | orderRepo  |
    | addressRepo |  | Repo        |  | reviewRepo |
    |             |  | menuRepo    |  | chatRepo   |
    +------------+  +------------+  +------------+
          |               |               |
    +-----+------+  +----+-------+  +----+-------+
    | Use Case    |  | Use Case   |  | Use Case   |
    | Providers   |  | Providers  |  | Providers  |
    +------------+  +------------+  +------------+
          |               |               |
    +-----+------+  +----+-------+  +----+-------+
    | Data/State  |  | Data/State |  | Data/State |
    | Providers   |  | Providers  |  | Providers  |
    +------------+  +------------+  +------------+
    | userProfile |  | nearbyRest.|  | activeOrder|
    | userAddrs   |  | restaurant |  | orderHist. |
    | roleState   |  | Detail     |  | orderTrack.|
    |             |  | menuItems  |  | chatMsgs   |
    +------------+  +------------+  +------------+
```

---

## Key Providers

### Authentication

```dart
// Stream of Firebase Auth state changes
@riverpod
Stream<User?> authState(AuthStateRef ref) {
  return FirebaseAuth.instance.authStateChanges();
}

// Current authenticated user (synchronous access)
@riverpod
User? currentUser(CurrentUserRef ref) {
  return ref.watch(authStateProvider).valueOrNull;
}

// User role from custom claims
@riverpod
Future<UserRole?> userRole(UserRoleRef ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final idTokenResult = await user.getIdTokenResult(true);
  final role = idTokenResult.claims?['role'] as String?;
  return role != null ? UserRole.fromString(role) : null;
}
```

### User Profile

```dart
// User profile from Firestore (reactive)
@riverpod
Stream<UserEntity> userProfile(UserProfileRef ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('Not authenticated');

  return FirebaseFirestore.instance
      .doc('users/${user.uid}')
      .snapshots()
      .map((doc) => UserModel.fromFirestore(doc));
}

// User addresses
@riverpod
Stream<List<AddressEntity>> userAddresses(UserAddressesRef ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('Not authenticated');

  return FirebaseFirestore.instance
      .collection('users/${user.uid}/addresses')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => AddressModel.fromFirestore(doc)).toList());
}
```

### Restaurants

```dart
// Nearby restaurants based on user location
@riverpod
Future<List<RestaurantEntity>> nearbyRestaurants(
  NearbyRestaurantsRef ref,
) async {
  final useCase = ref.watch(getNearbyRestaurantsUseCaseProvider);
  final location = await ref.watch(userLocationProvider.future);

  final result = await useCase(
    location: location,
    radiusKm: ref.watch(deliveryRadiusProvider),
  );

  return result.fold(
    (failure) => throw failure,
    (restaurants) => restaurants,
  );
}

// Single restaurant detail (reactive)
@riverpod
Stream<RestaurantEntity> restaurantDetail(
  RestaurantDetailRef ref,
  String restaurantId,
) {
  return FirebaseFirestore.instance
      .doc('restaurants/$restaurantId')
      .snapshots()
      .map((doc) => RestaurantModel.fromFirestore(doc));
}

// Menu items for a restaurant, grouped by category
@riverpod
Future<Map<CategoryEntity, List<MenuItemEntity>>> restaurantMenu(
  RestaurantMenuRef ref,
  String restaurantId,
) async {
  final categories = await ref.watch(
    menuCategoriesProvider(restaurantId).future,
  );
  final items = await ref.watch(
    menuItemsProvider(restaurantId).future,
  );

  final grouped = <CategoryEntity, List<MenuItemEntity>>{};
  for (final category in categories) {
    grouped[category] = items
        .where((item) => item.categoryId == category.id)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
  return grouped;
}
```

### Cart (Local State with Persistence)

```dart
@riverpod
class CartNotifier extends _$CartNotifier {
  late Box<CartItemModel> _cartBox;

  @override
  CartState build() {
    _cartBox = Hive.box<CartItemModel>('cart');
    return _loadFromHive();
  }

  CartState _loadFromHive() {
    final items = _cartBox.values.toList();
    if (items.isEmpty) return const CartState.empty();

    return CartState(
      restaurantId: items.first.restaurantId,
      restaurantName: items.first.restaurantName,
      items: items.map((m) => m.toEntity()).toList(),
    );
  }

  void _persistToHive() {
    _cartBox.clear();
    for (final item in state.items) {
      _cartBox.add(CartItemModel.fromEntity(item));
    }
  }

  void addItem(CartItemEntity item) {
    // Check if different restaurant
    if (state.restaurantId != null &&
        state.restaurantId != item.restaurantId) {
      // Caller should show confirmation dialog first
      throw DifferentRestaurantException();
    }

    final existingIndex = state.items.indexWhere(
      (i) => i.itemId == item.itemId && i.customizationsMatch(item),
    );

    if (existingIndex >= 0) {
      // Update quantity
      final updated = state.items[existingIndex].copyWith(
        quantity: state.items[existingIndex].quantity + item.quantity,
      );
      state = state.copyWith(
        items: [...state.items]..[existingIndex] = updated,
      );
    } else {
      state = state.copyWith(
        restaurantId: item.restaurantId,
        restaurantName: item.restaurantName,
        items: [...state.items, item],
      );
    }

    _persistToHive();
  }

  void removeItem(int index) {
    final items = [...state.items]..removeAt(index);
    state = items.isEmpty
        ? const CartState.empty()
        : state.copyWith(items: items);
    _persistToHive();
  }

  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      removeItem(index);
      return;
    }
    state = state.copyWith(
      items: [...state.items]
        ..[index] = state.items[index].copyWith(quantity: quantity),
    );
    _persistToHive();
  }

  void clearCart() {
    state = const CartState.empty();
    _cartBox.clear();
  }
}
```

### Orders

```dart
// Active orders for current customer (real-time)
@riverpod
Stream<List<OrderEntity>> activeOrders(ActiveOrdersRef ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('Not authenticated');

  return FirebaseFirestore.instance
      .collection('orders')
      .where('customerId', isEqualTo: user.uid)
      .where('status', whereIn: [
        'placed', 'confirmed', 'preparing', 'readyForPickup', 'pickedUp'
      ])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
}

// Order history (paginated, not real-time)
@riverpod
Future<List<OrderEntity>> orderHistory(
  OrderHistoryRef ref, {
  int page = 1,
  int pageSize = 10,
}) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('Not authenticated');

  final snapshot = await FirebaseFirestore.instance
      .collection('orders')
      .where('customerId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .limit(pageSize)
      .get();

  return snapshot.docs
      .map((doc) => OrderModel.fromFirestore(doc))
      .toList();
}
```

### Real-Time Tracking

```dart
// Delivery partner location (real-time for customer view)
@riverpod
Stream<DeliveryLocationEntity> deliveryPartnerLocation(
  DeliveryPartnerLocationRef ref,
  String deliveryPartnerId,
) {
  return FirebaseFirestore.instance
      .doc('delivery_locations/$deliveryPartnerId')
      .snapshots()
      .map((doc) => DeliveryLocationModel.fromFirestore(doc));
}

// Order status stream
@riverpod
Stream<OrderStatus> orderStatus(
  OrderStatusRef ref,
  String orderId,
) {
  return FirebaseFirestore.instance
      .doc('orders/$orderId')
      .snapshots()
      .map((doc) {
        final data = doc.data()!;
        return OrderStatus.fromString(data['status'] as String);
      });
}
```

### Chat

```dart
// Chat messages (real-time)
@riverpod
Stream<List<MessageEntity>> chatMessages(
  ChatMessagesRef ref,
  String chatId,
) {
  return FirebaseFirestore.instance
      .collection('chats/$chatId/messages')
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList());
}
```

### Notifications

```dart
// Unread notification count (real-time badge)
@riverpod
Stream<int> unreadNotificationCount(UnreadNotificationCountRef ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: user.uid)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.size);
}
```

### Admin Analytics

```dart
// Dashboard stats (cached)
@riverpod
Future<DashboardStats> dashboardStats(
  DashboardStatsRef ref,
  String dateRange,
) async {
  final callable = FirebaseFunctions.instance
      .httpsCallable('getDashboardStats');
  final result = await callable.call({'dateRange': dateRange});
  return DashboardStats.fromJson(result.data);
}

// Delivery partner count (real-time)
@riverpod
Stream<int> deliveryPartnerCount(DeliveryPartnerCountRef ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'deliveryPartner')
      .snapshots()
      .map((snapshot) => snapshot.size);
}
```

---

## Real-Time Data Patterns

### Pattern: Firestore Snapshot to StreamProvider

Most real-time data follows this pattern:

```dart
// 1. Repository method returns a Stream
abstract class OrderRepository {
  Stream<OrderEntity> watchOrder(String orderId);
}

// 2. Implementation uses Firestore snapshots
class OrderRepositoryImpl implements OrderRepository {
  @override
  Stream<OrderEntity> watchOrder(String orderId) {
    return _firestore
        .doc('orders/$orderId')
        .snapshots()
        .map((doc) => OrderModel.fromFirestore(doc));
  }
}

// 3. StreamProvider exposes to UI
@riverpod
Stream<OrderEntity> watchOrder(WatchOrderRef ref, String orderId) {
  return ref.watch(orderRepositoryProvider).watchOrder(orderId);
}

// 4. Widget consumes with ref.watch
class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(watchOrderProvider(orderId));

    return orderAsync.when(
      data: (order) => OrderTrackingView(order: order),
      loading: () => const OrderTrackingSkeleton(),
      error: (error, stack) => ErrorWidget(error: error),
    );
  }
}
```

### Pattern: Combining Multiple Streams

```dart
@riverpod
Stream<OrderTrackingData> orderTrackingData(
  OrderTrackingDataRef ref,
  String orderId,
) {
  final order$ = ref.watch(watchOrderProvider(orderId).stream);

  return order$.asyncExpand((order) {
    if (order.deliveryPartnerId == null || order.status != OrderStatus.pickedUp) {
      return Stream.value(OrderTrackingData(order: order, partnerLocation: null));
    }

    return ref
        .watch(deliveryPartnerLocationProvider(order.deliveryPartnerId!).stream)
        .map((location) => OrderTrackingData(
              order: order,
              partnerLocation: location,
            ));
  });
}
```

---

## Testing Strategy

### Unit Testing Providers

Riverpod's `ProviderContainer` allows testing providers in isolation:

```dart
void main() {
  group('nearbyRestaurants', () {
    test('returns restaurants when use case succeeds', () async {
      final container = ProviderContainer(
        overrides: [
          // Override the use case with a mock
          getNearbyRestaurantsUseCaseProvider.overrideWithValue(
            MockGetNearbyRestaurants(),
          ),
          // Override location
          userLocationProvider.overrideWith(
            (ref) async => const GeoPoint(40.7128, -74.0060),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Set up mock behavior
      when(container.read(getNearbyRestaurantsUseCaseProvider).call(
        location: anyNamed('location'),
        radiusKm: anyNamed('radiusKm'),
      )).thenAnswer((_) async => Right(testRestaurants));

      // Read the provider
      final restaurants = await container.read(
        nearbyRestaurantsProvider.future,
      );

      expect(restaurants, testRestaurants);
    });

    test('throws when use case fails', () async {
      final container = ProviderContainer(
        overrides: [
          getNearbyRestaurantsUseCaseProvider.overrideWithValue(
            MockGetNearbyRestaurants(),
          ),
          userLocationProvider.overrideWith(
            (ref) async => const GeoPoint(40.7128, -74.0060),
          ),
        ],
      );
      addTearDown(container.dispose);

      when(container.read(getNearbyRestaurantsUseCaseProvider).call(
        location: anyNamed('location'),
        radiusKm: anyNamed('radiusKm'),
      )).thenAnswer((_) async => Left(ServerFailure('Network error')));

      expect(
        () => container.read(nearbyRestaurantsProvider.future),
        throwsA(isA<ServerFailure>()),
      );
    });
  });
}
```

### Widget Testing with Overrides

```dart
void main() {
  testWidgets('CartScreen shows items from cart provider', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cartNotifierProvider.overrideWith(() => MockCartNotifier()),
        ],
        child: const MaterialApp(
          home: CartScreen(),
        ),
      ),
    );

    expect(find.text('Margherita Pizza'), findsOneWidget);
    expect(find.text('Caesar Salad'), findsOneWidget);
  });
}
```

### Mocking Notifiers

```dart
class MockCartNotifier extends CartNotifier {
  @override
  CartState build() {
    return CartState(
      restaurantId: 'rest_1',
      restaurantName: 'Test Restaurant',
      items: [
        CartItemEntity(
          itemId: 'item_1',
          name: 'Margherita Pizza',
          basePrice: 1299,
          quantity: 2,
          customizations: [],
        ),
        CartItemEntity(
          itemId: 'item_2',
          name: 'Caesar Salad',
          basePrice: 899,
          quantity: 1,
          customizations: [],
        ),
      ],
    );
  }
}
```

---

## Best Practices

| Practice | Description |
| -------- | ----------- |
| **Use `ref.watch` for reactive data** | Automatically rebuilds when dependencies change |
| **Use `ref.read` for one-time actions** | Button handlers, initialization, fire-and-forget |
| **Use `ref.listen` for side effects** | Navigation, showing snackbars, logging |
| **Keep providers small and focused** | One provider per piece of data or behavior |
| **Use family providers for parameterized data** | `restaurantDetailProvider(restaurantId)` |
| **Dispose heavy resources** | Use `ref.onDispose` for timers, listeners, controllers |
| **Handle all AsyncValue states** | Always handle `.data`, `.loading`, and `.error` |
| **Avoid provider chains > 3 levels** | Deep chains make debugging harder |
| **Use `select` for granular rebuilds** | `ref.watch(provider.select((s) => s.name))` |
| **Generate providers with `@riverpod`** | Consistent naming, auto-disposal, less boilerplate |
