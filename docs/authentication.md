# Authentication

This document describes the authentication and role flow implemented in the app today.

## Source Of Truth

- Auth data source: `lib/features/auth/data/datasources/auth_remote_datasource.dart`
- Auth repository: `lib/features/auth/data/repositories/auth_repository_impl.dart`
- Auth model: `lib/features/auth/data/models/user_model.dart`
- Auth entity: `lib/features/auth/domain/entities/app_user.dart`
- Auth state/provider: `lib/features/auth/presentation/providers/auth_provider.dart`
- Auth screens:
  - `lib/features/auth/presentation/screens/login_screen.dart`
  - `lib/features/auth/presentation/screens/register_screen.dart`
  - `lib/features/auth/presentation/screens/phone_verification_screen.dart`
  - `lib/features/auth/presentation/screens/forgot_password_screen.dart`
  - `lib/features/auth/presentation/screens/role_selection_screen.dart`
  - `lib/features/auth/presentation/screens/splash_screen.dart`
- Router integration: `lib/routing/app_router.dart`
- Callable wrapper: `lib/core/network/firebase_callable.dart`
- Role constants: `lib/core/enums/user_role.dart`
- Firestore rules: `firestore.rules`
- Cloud Function for admin role updates: `functions/src/auth/set_user_role.ts`

## Supported Sign-In Methods

| Method | Status | Notes |
| ------ | ------ | ----- |
| Email / Password | Implemented | Main sign-in and sign-up flow |
| Phone OTP | Implemented | Uses `FirebaseAuth.verifyPhoneNumber` |
| Google Sign-In | Not currently wired in these screens | Do not treat as current app flow |

## User Record Model

The app stores user profile data in `users/{uid}` and uses the `role` field from:

1. Firebase custom claims when available
2. Firestore `users/{uid}.role` as fallback

The current supported roles are:

- `customer`
- `deliveryPartner`
- `restaurantOwner`
- `admin`

These values are defined in `lib/core/enums/user_role.dart`.

## Current Sign-Up Flow

### Email Sign-Up

Implemented in:

- `lib/features/auth/presentation/screens/register_screen.dart`
- `lib/features/auth/presentation/providers/auth_provider.dart`
- `lib/features/auth/data/datasources/auth_remote_datasource.dart`

Current behavior:

1. User registers with email and password.
2. Firebase Auth user is created.
3. `saveUserToFirestore()` creates or merges the user document.
4. New users start with `role: customer`.
5. UI navigates to `/auth/role-selection`.

### Phone Sign-In

Implemented in:

- `lib/features/auth/presentation/screens/phone_verification_screen.dart`
- `lib/features/auth/presentation/providers/auth_provider.dart`
- `lib/features/auth/data/datasources/auth_remote_datasource.dart`

Current behavior:

1. User requests OTP.
2. Firebase sends code.
3. User submits OTP.
4. Existing Firestore user is loaded when present.
5. Otherwise a new Firestore user document is created.
6. UI navigates to `/auth/role-selection`.

## Current Role Selection Flow

Implemented in:

- `lib/features/auth/presentation/screens/role_selection_screen.dart`
- `lib/features/auth/presentation/providers/auth_provider.dart`
- `lib/features/auth/data/datasources/auth_remote_datasource.dart`

Current behavior:

1. Auth screens navigate to `/auth/role-selection`.
2. User chooses one of:
   - customer
   - restaurant owner
   - delivery partner
3. `AuthNotifier.updateUserRole()` updates `users/{uid}.role`.
4. The notifier reloads the current user and emits `Authenticated(user.copyWith(role: role))`.
5. `RoleSelectionScreen` routes by selected role:
   - customer -> `/customer/home`
   - delivery partner -> `/delivery/home`
   - restaurant owner -> `/restaurant/setup`
   - admin -> `/admin/dashboard`

## Current Restaurant Owner Flow

Relevant files:

- `lib/features/auth/presentation/screens/role_selection_screen.dart`
- `lib/features/restaurant_owner/presentation/screens/restaurant_setup_screen.dart`
- `lib/features/restaurant_owner/presentation/screens/restaurant_dashboard_screen.dart`
- `lib/routing/shell_routes/restaurant_owner_shell.dart`

Current app behavior:

1. User signs in.
2. User goes to `/auth/role-selection`.
3. User picks `I Own a Restaurant`.
4. User role is updated to `restaurantOwner`.
5. User is sent to `/restaurant/setup`.
6. Owner shell routes live under `/restaurant/*`.

Current limitation:

- Restaurant setup submission is still placeholder UI and is not yet fully connected to restaurant creation/persistence.

## Current Router Role Resolution

The router does not rely only on token claims anymore.

`currentUserRoleProvider` in `lib/features/auth/presentation/providers/auth_provider.dart` resolves role through the auth repository, which ultimately checks:

1. Firebase custom claims
2. Firestore `users/{uid}.role`

This is important because self-service role selection currently updates Firestore directly.

## Admin Role Changes

Admin-driven role changes are handled by Cloud Functions in:

- `functions/src/auth/set_user_role.ts`

Current behavior:

- Callable name: `setUserRole`
- Caller must already be `admin`
- Function updates both:
  - Firebase custom claims
  - Firestore `users/{uid}.role`

This path should still be used for privileged role changes, especially admin assignment.

## Firestore Rules And Current Role Policy

Current rules live in `firestore.rules`.

Important behavior:

- Users cannot promote themselves to `admin`.
- Users can currently self-select `customer`, `deliveryPartner`, or `restaurantOwner` during onboarding by updating only:
  - `role`
  - `updatedAt`

This matches the current app flow in `RoleSelectionScreen`.

## App Launch Flow

Current runtime behavior:

1. App starts.
2. Router checks auth state.
3. If signed out, protected routes redirect to `/auth/login`.
4. If signed in, router resolves role from `currentUserRoleProvider`.
5. If role is missing, router redirects to `/auth/role-selection`.
6. If role exists, router enforces the correct route prefix.

## Current Gaps

- There is no fully implemented onboarding-completion guard yet.
- Owner setup completion is not yet enforced by router state.
- Delivery verification is not currently modeled in the same detailed way older docs described.
- Any older docs that mention `/login`, `/signup`, `/otp-verification`, or customer-only custom claim flow should be considered outdated in favor of the files listed above.
