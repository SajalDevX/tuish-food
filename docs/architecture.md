# Architecture

This document describes the architectural patterns, project structure, and design decisions behind the Tuish Food application.

---

## Clean Architecture Overview

Tuish Food follows **Clean Architecture** principles adapted for Flutter. The codebase is organized with a strict dependency rule: inner layers never import from outer layers.

```
+---------------------------------------------------------------+
|                      Presentation Layer                       |
|  (Widgets, Screens, Providers/Notifiers, ViewModels)          |
+---------------------------------------------------------------+
        |                       |                       |
        v                       v                       v
+---------------------------------------------------------------+
|                        Domain Layer                           |
|  (Entities, Use Cases, Repository Interfaces, Failures)       |
+---------------------------------------------------------------+
        |                       |                       |
        v                       v                       v
+---------------------------------------------------------------+
|                         Data Layer                            |
|  (Models, Repository Implementations, Data Sources, DTOs)     |
+---------------------------------------------------------------+
        |                       |                       |
        v                       v                       v
+---------------------------------------------------------------+
|                     External Services                         |
|  (Firebase, Google Maps API, Stripe API, Hive, Device APIs)   |
+---------------------------------------------------------------+
```

### Layer Responsibilities

| Layer | Responsibility | Depends On |
| ----- | -------------- | ---------- |
| **Presentation** | UI rendering, user interaction, state management (Riverpod providers/notifiers) | Domain |
| **Domain** | Business logic, entities, use case definitions, repository contracts | Nothing (pure Dart) |
| **Data** | Data fetching, caching, serialization, repository implementations | Domain (implements interfaces) |

### The Dependency Rule

The most important rule: **source code dependencies only point inward**.

- The Domain layer has **zero imports** from Presentation or Data.
- The Data layer imports from Domain (to implement repository interfaces and use entities).
- The Presentation layer imports from Domain (to call use cases and reference entities).
- The Data layer is injected into the Domain layer via **dependency inversion** (repository interfaces).

---

## Features-First Structure

Instead of grouping by layer (all models in one folder, all screens in another), Tuish Food groups by **feature**. Each feature is a self-contained module with its own layers.

```
lib/
  core/
    constants/
      app_constants.dart
      api_constants.dart
    errors/
      failures.dart
      exceptions.dart
    network/
      network_info.dart
    theme/
      app_theme.dart
      app_colors.dart
      app_typography.dart
    utils/
      validators.dart
      formatters.dart
      extensions.dart

  features/
    auth/
      data/
        datasources/
          auth_remote_datasource.dart
        models/
          user_model.dart
        repositories/
          auth_repository_impl.dart
      domain/
        entities/
          user_entity.dart
        repositories/
          auth_repository.dart          # Abstract
        usecases/
          sign_in_with_email.dart
          sign_in_with_google.dart
          sign_up.dart
          sign_out.dart
          get_current_user.dart
      presentation/
        providers/
          auth_provider.dart
        screens/
          login_screen.dart
          signup_screen.dart
          otp_verification_screen.dart
        widgets/
          auth_form.dart
          social_login_buttons.dart

    customer/
      home/
        data/ ...
        domain/ ...
        presentation/ ...
      restaurant_detail/
        data/ ...
        domain/ ...
        presentation/ ...
      cart/
        data/ ...
        domain/ ...
        presentation/ ...
      checkout/
        ...
      order_tracking/
        ...

    delivery/
      dashboard/
        ...
      active_delivery/
        ...
      earnings/
        ...

    admin/
      dashboard/
        ...
      restaurant_management/
        ...
      user_management/
        ...
      order_management/
        ...

    orders/           # Shared order domain (used by customer, delivery, admin)
      data/ ...
      domain/ ...
      presentation/ ...

    chat/
      data/ ...
      domain/ ...
      presentation/ ...

    tracking/
      data/ ...
      domain/ ...
      presentation/ ...

    payments/
      data/ ...
      domain/ ...
      presentation/ ...

    notifications/
      data/ ...
      domain/ ...
      presentation/ ...

  shared/
    widgets/
      tuish_button.dart
      tuish_text_field.dart
      tuish_card.dart
      loading_skeleton.dart
      status_badge.dart
      rating_bar.dart
      price_tag.dart
      error_widget.dart
      empty_state_widget.dart
    providers/
      shared_providers.dart
    models/
      geolocation.dart

  app.dart
  main.dart
```

---

## Entity vs Model

The distinction between Entity and Model is fundamental to the architecture.

### Entity (Domain Layer)

Entities represent core business objects. They are **immutable**, contain **no serialization logic**, and live in the domain layer.

```dart
// domain/entities/restaurant_entity.dart
class RestaurantEntity {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final GeoPoint location;
  final bool isOpen;
  final List<String> cuisineTypes;

  const RestaurantEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.location,
    required this.isOpen,
    required this.cuisineTypes,
  });
}
```

### Model (Data Layer)

Models extend or map to entities and include serialization logic (`fromJson`, `toJson`, `fromFirestore`). They handle the translation between external data formats and domain entities.

```dart
// data/models/restaurant_model.dart
class RestaurantModel extends RestaurantEntity {
  const RestaurantModel({
    required super.id,
    required super.name,
    required super.description,
    required super.imageUrl,
    required super.rating,
    required super.reviewCount,
    required super.location,
    required super.isOpen,
    required super.cuisineTypes,
  });

  factory RestaurantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RestaurantModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      location: data['location'] as GeoPoint,
      isOpen: data['isOpen'] ?? false,
      cuisineTypes: List<String>.from(data['cuisineTypes'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'location': location,
      'isOpen': isOpen,
      'cuisineTypes': cuisineTypes,
    };
  }
}
```

---

## Repository Pattern

Repositories provide a clean interface between the domain and data layers.

### Abstract Repository (Domain Layer)

Defines the contract. Uses `Either<Failure, T>` from `dartz` to represent success/failure without exceptions.

```dart
// domain/repositories/restaurant_repository.dart
abstract class RestaurantRepository {
  Future<Either<Failure, List<RestaurantEntity>>> getNearbyRestaurants({
    required GeoPoint location,
    required double radiusKm,
  });

  Future<Either<Failure, RestaurantEntity>> getRestaurantById(String id);

  Stream<Either<Failure, List<RestaurantEntity>>> watchRestaurants();

  Future<Either<Failure, void>> createRestaurant(RestaurantEntity restaurant);

  Future<Either<Failure, void>> updateRestaurant(RestaurantEntity restaurant);

  Future<Either<Failure, void>> deleteRestaurant(String id);
}
```

### Repository Implementation (Data Layer)

Implements the abstract repository, handles data sources, error mapping, and caching.

```dart
// data/repositories/restaurant_repository_impl.dart
class RestaurantRepositoryImpl implements RestaurantRepository {
  final FirebaseFirestore _firestore;

  RestaurantRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, List<RestaurantEntity>>> getNearbyRestaurants({
    required GeoPoint location,
    required double radiusKm,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('restaurants')
          .where('isActive', isEqualTo: true)
          .get();

      final restaurants = snapshot.docs
          .map((doc) => RestaurantModel.fromFirestore(doc))
          .where((r) => _isWithinRadius(r.location, location, radiusKm))
          .toList();

      return Right(restaurants);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Firestore error'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  // ... other implementations
}
```

---

## Use Case Pattern

Each use case encapsulates a single business operation. This enforces the **Single Responsibility Principle** and makes business logic easily testable.

```dart
// domain/usecases/get_nearby_restaurants.dart
class GetNearbyRestaurants {
  final RestaurantRepository repository;

  GetNearbyRestaurants(this.repository);

  Future<Either<Failure, List<RestaurantEntity>>> call({
    required GeoPoint location,
    required double radiusKm,
  }) {
    return repository.getNearbyRestaurants(
      location: location,
      radiusKm: radiusKm,
    );
  }
}
```

Use cases are invoked from Riverpod providers in the presentation layer:

```dart
@riverpod
Future<List<RestaurantEntity>> nearbyRestaurants(
  NearbyRestaurantsRef ref,
) async {
  final location = await ref.watch(userLocationProvider.future);
  final useCase = ref.watch(getNearbyRestaurantsUseCaseProvider);

  final result = await useCase(
    location: location,
    radiusKm: 10.0,
  );

  return result.fold(
    (failure) => throw failure,
    (restaurants) => restaurants,
  );
}
```

---

## Error Handling

Tuish Food uses the `dartz` package for functional error handling. Instead of throwing exceptions across layer boundaries, every operation returns `Either<Failure, T>`.

### Failure Hierarchy

```dart
// core/errors/failures.dart
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;
  const ValidationFailure(super.message, {this.fieldErrors});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied']);
}
```

### Exception to Failure Mapping

Exceptions are caught at the data layer boundary and converted to Failures:

```dart
Either<Failure, T> _handleException<T>(Object e) {
  if (e is FirebaseAuthException) {
    return Left(AuthFailure(e.message ?? 'Authentication error', code: e.code));
  } else if (e is FirebaseException) {
    return Left(ServerFailure(e.message ?? 'Server error', code: e.code));
  } else if (e is SocketException) {
    return Left(const NetworkFailure());
  } else {
    return Left(ServerFailure('Unexpected error: $e'));
  }
}
```

### Using Either in the Presentation Layer

```dart
// In a Riverpod Notifier
Future<void> placeOrder(OrderEntity order) async {
  state = const AsyncValue.loading();

  final result = await _placeOrderUseCase(order);

  state = result.fold(
    (failure) => AsyncValue.error(failure, StackTrace.current),
    (order) => AsyncValue.data(order),
  );
}
```

---

## Provider / State Flow

The following diagram shows how data flows through the architecture via Riverpod providers:

```
  User Interaction (tap, scroll, type)
         |
         v
  +------------------+
  |  Screen / Widget  |  <-- ref.watch(someProvider)
  +------------------+
         |
         v
  +---------------------+
  |  Riverpod Provider   |  <-- NotifierProvider, FutureProvider, StreamProvider
  |  (Presentation)      |
  +---------------------+
         |
         v
  +------------------+
  |    Use Case       |  <-- Single business operation
  |    (Domain)       |
  +------------------+
         |
         v
  +------------------------+
  |  Repository Interface   |  <-- Abstract contract (Domain)
  +------------------------+
         |
         v (via dependency injection)
  +------------------------+
  |  Repository Impl        |  <-- Concrete implementation (Data)
  +------------------------+
         |
         v
  +------------------------+
  |  Data Source             |  <-- Firestore, REST API, Hive, etc.
  +------------------------+
         |
         v
  +------------------------+
  |  External Service        |  <-- Firebase, Google Maps, Stripe
  +------------------------+
```

### Dependency Injection with Riverpod

Repositories and use cases are provided through Riverpod, enabling easy testing via overrides:

```dart
// Repository provider
@riverpod
RestaurantRepository restaurantRepository(RestaurantRepositoryRef ref) {
  return RestaurantRepositoryImpl(FirebaseFirestore.instance);
}

// Use case provider
@riverpod
GetNearbyRestaurants getNearbyRestaurantsUseCase(
  GetNearbyRestaurantsUseCaseRef ref,
) {
  return GetNearbyRestaurants(ref.watch(restaurantRepositoryProvider));
}

// Data provider (used by UI)
@riverpod
Future<List<RestaurantEntity>> nearbyRestaurants(
  NearbyRestaurantsRef ref,
) async {
  final useCase = ref.watch(getNearbyRestaurantsUseCaseProvider);
  final location = await ref.watch(userLocationProvider.future);

  final result = await useCase(location: location, radiusKm: 10.0);
  return result.fold(
    (failure) => throw failure,
    (restaurants) => restaurants,
  );
}
```

---

## Key Design Decisions

| Decision | Rationale |
| -------- | --------- |
| Features-first over layers-first | Co-locates related code, scales better with team size, each feature is self-contained |
| dartz Either over try-catch | Compile-time error handling, forces callers to handle failures, no uncaught exceptions |
| Entity/Model separation | Domain stays pure Dart, serialization concerns isolated to data layer |
| Riverpod over BLoC | Less boilerplate, compile-safe, no BuildContext dependency, better testing story |
| Use cases as classes | Single Responsibility, easy to test, easy to compose, clear business logic boundary |
| Repository abstraction | Swap data sources without touching business logic, enables mocking in tests |

---

## Testing Strategy

The layered architecture enables focused testing at each level:

| Layer | Test Type | What to Test |
| ----- | --------- | ------------ |
| Domain (Use Cases) | Unit tests | Business logic, edge cases, failure handling |
| Data (Repositories) | Unit tests with mocks | Serialization, error mapping, data source integration |
| Presentation (Providers) | Unit tests with ProviderScope overrides | State transitions, UI logic |
| Widgets | Widget tests | Rendering, interaction, navigation |
| Full app | Integration tests | End-to-end user flows |

```dart
// Example: Testing a use case
test('should return restaurants when repository succeeds', () async {
  when(mockRepository.getNearbyRestaurants(
    location: anyNamed('location'),
    radiusKm: anyNamed('radiusKm'),
  )).thenAnswer((_) async => Right(testRestaurants));

  final result = await useCase(
    location: const GeoPoint(0, 0),
    radiusKm: 10.0,
  );

  expect(result.isRight(), true);
  result.fold(
    (_) => fail('Should be Right'),
    (restaurants) => expect(restaurants, testRestaurants),
  );
});
```
