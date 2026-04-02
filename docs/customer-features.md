# Customer Features

This document summarizes the customer-facing functionality currently present in the app.

## Source Of Truth

- Routes: `lib/routing/app_router.dart`, `lib/routing/route_paths.dart`
- Home: `lib/features/customer/home/presentation/screens/customer_home_screen.dart`
- Restaurant detail: `lib/features/customer/home/presentation/screens/restaurant_detail_screen.dart`
- Cart: `lib/features/customer/cart/presentation/screens/cart_screen.dart`
- Checkout:
  - `lib/features/customer/checkout/presentation/screens/checkout_screen.dart`
  - `lib/features/customer/checkout/presentation/screens/address_selection_screen.dart`
  - `lib/features/customer/checkout/presentation/screens/payment_method_screen.dart`
  - `lib/features/customer/checkout/presentation/screens/order_confirmation_screen.dart`
- Orders:
  - `lib/features/customer/orders/presentation/screens/orders_list_screen.dart`
  - `lib/features/customer/orders/presentation/screens/order_detail_screen.dart`
- Tracking: `lib/features/customer/tracking/presentation/screens/live_tracking_screen.dart`
- Reviews: `lib/features/customer/reviews/presentation/screens/write_review_screen.dart`
- Profile:
  - `lib/features/customer/profile/presentation/screens/profile_screen.dart`
  - `lib/features/customer/profile/presentation/screens/edit_profile_screen.dart`
  - `lib/features/customer/profile/presentation/screens/addresses_screen.dart`
  - `lib/features/customer/profile/presentation/screens/add_address_screen.dart`
  - `lib/features/customer/profile/presentation/screens/settings_screen.dart`

## Current Customer Routes

- `/customer/home`
- `/customer/home/restaurant/:id`
- `/customer/home/search`
- `/customer/orders`
- `/customer/orders/:orderId`
- `/customer/orders/:orderId/tracking`
- `/customer/orders/:orderId/review`
- `/customer/orders/:orderId/chat`
- `/customer/cart`
- `/customer/profile`
- `/customer/profile/edit`
- `/customer/profile/addresses`
- `/customer/profile/addresses/add`
- `/customer/profile/settings`
- `/customer/profile/notifications`

Checkout is a full-screen flow outside the customer shell:

- `/checkout`
- `/checkout/address`
- `/checkout/payment`
- `/checkout/confirmation/:orderId`

## Implemented Areas

### Home And Restaurant Discovery

Current customer browsing flow includes:

- customer home screen
- restaurant cards/listing UI
- search screen
- restaurant detail screen

### Cart And Checkout

Current customer ordering flow includes:

- cart screen
- checkout screen
- address selection
- payment method selection
- order confirmation

### Orders And Tracking

Current order flow includes:

- order list
- order detail
- live tracking
- review submission
- chat route

### Profile And Addresses

Current profile area includes:

- edit profile
- saved addresses
- add address
- settings
- notifications screen

## Current Data Model Notes

Customer profile data currently comes from the shared auth user model, which stores:

- `email`
- `phone`
- `displayName`
- `photoUrl`
- `role`
- `isActive`
- `isBanned`

Customer addresses are stored under:

- `users/{uid}/addresses/{addressId}`

## Removed / Not Current

The current codebase does not show an implemented favorites feature for customers.

Do not document the following as active customer features unless the code is added:

- favorites screen
- `favoriteRestaurants` in the user model
- favorites provider flow

If favorites return later, they should be documented as a new feature instead of kept as assumed behavior.
