# Delivery Partner Features

This document describes the delivery-partner experience that is currently present in the app.

## Source Of Truth

- Routes: `lib/routing/app_router.dart`, `lib/routing/route_paths.dart`
- Shell: `lib/routing/shell_routes/delivery_shell.dart`
- Dashboard: `lib/features/delivery/dashboard/presentation/screens/delivery_home_screen.dart`
- Available/active delivery screens:
  - `lib/features/delivery/dashboard/presentation/screens/available_orders_screen.dart`
  - `lib/features/delivery/dashboard/presentation/screens/active_delivery_screen.dart`
- Earnings:
  - `lib/features/delivery/earnings/presentation/screens/earnings_screen.dart`
- Navigation:
  - `lib/features/delivery/navigation/presentation/screens/delivery_navigation_screen.dart`
- Profile:
  - `lib/features/delivery/profile/presentation/screens/delivery_profile_screen.dart`
  - `lib/features/delivery/profile/presentation/screens/vehicle_info_screen.dart`

## Current Flow

Current delivery role flow:

1. User signs in.
2. User reaches `/auth/role-selection`.
3. User selects delivery partner.
4. App updates `users/{uid}.role` to `deliveryPartner`.
5. User is routed to `/delivery/home`.

Current delivery shell routes:

- `/delivery/home`
- `/delivery/orders`
- `/delivery/earnings`
- `/delivery/profile`

Nested delivery routes:

- `/delivery/orders/:orderId`
- `/delivery/orders/:orderId/navigate`
- `/delivery/orders/:orderId/chat`

## Implemented Screens

### Delivery Home

`DeliveryHomeScreen` currently provides:

- online/offline toggle
- active delivery summary card
- quick stats
- available orders preview
- refresh of active delivery, available orders, and delivery history

### Orders

The delivery orders area currently uses:

- `AvailableOrdersScreen`
- `ActiveDeliveryScreen`
- `DeliveryNavigationScreen`
- shared chat route under `/delivery/orders/:orderId/chat`

### Earnings

`EarningsScreen` and related widgets present:

- earnings summary
- charts
- payout history UI

### Profile

Delivery profile currently includes:

- basic profile screen
- vehicle info editing in `VehicleInfoScreen`

Vehicle info is currently stored in the user document under:

```json
{
  "vehicleInfo": {
    "vehicleType": "Motorcycle",
    "vehicleNumber": "XX-00-AB-1234",
    "licenseNumber": "DL123456"
  }
}
```

## Current Data Used By The App

Current delivery-related user data used in the app includes:

- `role`
- `isActive`
- `isBanned`
- `vehicleInfo.vehicleType`
- `vehicleInfo.vehicleNumber`
- `vehicleInfo.licenseNumber`

Location data is stored in:

- `delivery_locations/{partnerId}`

Earnings data is stored in:

- `earnings/{earningsId}`

## Current Limitations

The following items are not fully wired as a complete end-to-end product flow yet:

- delivery-partner application / verification pipeline
- verification pending and rejection screens
- document upload / review workflow
- router-level verification gating

Some admin screens still use delivery-partner terminology like `Pending`, `Verified`, and `Rejected`, but that is currently modeled with `isActive` and `isBanned` behavior in UI logic rather than a complete verification-state system.

## Planned / Partial Areas

These concepts still appear elsewhere in older docs but are not currently implemented as a complete flow:

- `verificationStatus`
- partner registration route
- verification pending route
- rejection/resubmission route
- delivery document review flow

When documenting new delivery work, prefer separating:

- `Current behavior`
- `Current limitation`
- `Planned behavior`
