# Navigation

This document describes the current routing setup used by the app today.

## Source Of Truth

- Router: `lib/routing/app_router.dart`
- Route names: `lib/routing/route_names.dart`
- Route paths: `lib/routing/route_paths.dart`
- Shells:
  - `lib/routing/shell_routes/customer_shell.dart`
  - `lib/routing/shell_routes/delivery_shell.dart`
  - `lib/routing/shell_routes/restaurant_owner_shell.dart`
  - `lib/routing/shell_routes/admin_shell.dart`
- Auth role state used by router: `lib/features/auth/presentation/providers/auth_provider.dart`

## App Integration

`lib/app.dart` reads `routerProvider` and passes it to `MaterialApp.router`.

## Current Route Tree

```text
/
+-- /auth/login
+-- /auth/register
+-- /auth/phone-verify
+-- /auth/forgot-password
+-- /auth/role-selection
|
+-- /checkout
|     +-- /checkout/address
|     +-- /checkout/payment
|     +-- /checkout/confirmation/:orderId
|
+-- /customer/home
|     +-- /customer/home/restaurant/:id
|     +-- /customer/home/search
|-- /customer/orders
|     +-- /customer/orders/:orderId
|           +-- /tracking
|           +-- /review
|           +-- /chat
|-- /customer/cart
|-- /customer/profile
|     +-- /edit
|     +-- /addresses
|     |     +-- /add
|     +-- /settings
|     +-- /notifications
|
+-- /delivery/home
|     +-- /active/:orderId
|-- /delivery/orders
|     +-- /:orderId/navigate
|     +-- /:orderId/chat
|-- /delivery/earnings
|-- /delivery/profile
|
+-- /restaurant/setup
+-- /restaurant/dashboard
|-- /restaurant/menu
|     +-- /add
|     +-- /:itemId/edit
|-- /restaurant/orders
|     +-- /:orderId
|-- /restaurant/profile
|
+-- /admin/dashboard
|-- /admin/restaurants
|     +-- /add
|     +-- /:id/edit
|     +-- /:id/menu
|-- /admin/users
|     +-- /:id
|-- /admin/delivery-partners
|-- /admin/orders
|     +-- /:orderId
|-- /admin/promotions
|     +-- /create
|-- /admin/settings
```

## Shell Navigation

### Customer

Implemented with a `StatefulShellRoute`.

| Index | Label | Route |
| ----- | ----- | ----- |
| 0 | Home | `/customer/home` |
| 1 | Orders | `/customer/orders` |
| 2 | Cart | `/customer/cart` |
| 3 | Profile | `/customer/profile` |

### Delivery

Implemented with a `StatefulShellRoute`.

| Index | Label | Route |
| ----- | ----- | ----- |
| 0 | Home | `/delivery/home` |
| 1 | Orders | `/delivery/orders` |
| 2 | Earnings | `/delivery/earnings` |
| 3 | Profile | `/delivery/profile` |

### Restaurant Owner

Implemented with a `StatefulShellRoute`.

| Index | Label | Route |
| ----- | ----- | ----- |
| 0 | Dashboard | `/restaurant/dashboard` |
| 1 | Menu | `/restaurant/menu` |
| 2 | Orders | `/restaurant/orders` |
| 3 | Profile | `/restaurant/profile` |

### Admin

Implemented with `ShellRoute` and `AdminShell`.

| Label | Route |
| ----- | ----- |
| Dashboard | `/admin/dashboard` |
| Restaurants | `/admin/restaurants` |
| Users | `/admin/users` |
| Delivery Partners | `/admin/delivery-partners` |
| Orders | `/admin/orders` |
| Promotions | `/admin/promotions` |
| Settings | `/admin/settings` |

## Redirect Logic

`lib/routing/app_router.dart` handles redirects centrally.

Current behavior:

1. If the user is not signed in and tries to open a protected route, redirect to `/auth/login`.
2. If the user is signed in and opens an auth route other than `/auth/role-selection`, redirect to the role landing path.
3. If the user is signed in but no role is resolved yet, redirect to `/auth/role-selection`.
4. If the user opens a route for the wrong role prefix, redirect to that role's home route.

The router currently reads role state from `currentUserRoleProvider` in:

- `lib/features/auth/presentation/providers/auth_provider.dart`

That provider uses the auth repository and falls back to Firestore role data when needed.

## Current Role Landing Paths

| Role | Landing Route |
| ---- | ------------- |
| customer | `/customer/home` |
| deliveryPartner | `/delivery/home` |
| restaurantOwner | `/restaurant/dashboard` |
| admin | `/admin/dashboard` |
| unresolved | `/auth/role-selection` |

## Current Restaurant Owner Flow

Relevant files:

- `lib/features/auth/presentation/screens/login_screen.dart`
- `lib/features/auth/presentation/screens/register_screen.dart`
- `lib/features/auth/presentation/screens/phone_verification_screen.dart`
- `lib/features/auth/presentation/screens/role_selection_screen.dart`
- `lib/features/auth/presentation/providers/auth_provider.dart`
- `lib/features/auth/data/datasources/auth_remote_datasource.dart`
- `lib/features/restaurant_owner/presentation/screens/restaurant_setup_screen.dart`
- `lib/features/restaurant_owner/presentation/screens/restaurant_dashboard_screen.dart`

Current flow:

1. Sign in or register.
2. Navigate to `/auth/role-selection`.
3. Choose `I Own a Restaurant`.
4. `AuthNotifier.updateUserRole()` writes `restaurantOwner`.
5. Router resolves the owner role.
6. `RoleSelectionScreen` sends the user to `/restaurant/setup`.
7. The persistent owner shell is available under `/restaurant/dashboard`, `/restaurant/menu`, `/restaurant/orders`, and `/restaurant/profile`.

## Current Limitations

- `lib/routing/guards/onboarding_guard.dart` is still a placeholder.
- The restaurant setup and dashboard screens are present, but restaurant persistence and completion gating are not fully implemented yet.
- Deep links documented elsewhere should target the current paths in `route_paths.dart`, not older `/login` or `/signup` paths.
