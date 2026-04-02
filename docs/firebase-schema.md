# Firebase Schema

This document describes the Firestore collections and core fields that are actively used by the current app and Cloud Functions.

## Source Of Truth

- Firestore rules: `firestore.rules`
- Auth user model: `lib/features/auth/data/models/user_model.dart`
- Restaurant model: `lib/features/customer/home/data/models/restaurant_model.dart`
- Auth trigger: `functions/src/auth/on_user_created.ts`
- Shared constants: `functions/src/utils/constants.ts`

## Schema Overview

```text
Firestore Root
  +-- users/{userId}
  |     +-- addresses/{addressId}
  +-- restaurants/{restaurantId}
  |     +-- menuCategories/{categoryId}
  |     +-- menuItems/{itemId}
  +-- orders/{orderId}
  +-- reviews/{reviewId}
  +-- delivery_locations/{partnerId}
  +-- chats/{chatId}
  |     +-- messages/{messageId}
  +-- earnings/{earningsId}
  +-- promotions/{promotionId}
  +-- notifications/{notificationId}
  +-- app_config/{document}
```

## Users

Collection:

- `users/{userId}`

Current core fields used by auth/app code:

| Field | Type | Notes |
| ----- | ---- | ----- |
| `email` | `string?` | Email address |
| `phone` | `string?` | Current field name used by code and auth trigger |
| `displayName` | `string?` | Display name |
| `photoUrl` | `string?` | Profile photo |
| `role` | `string` | `customer`, `deliveryPartner`, `restaurantOwner`, `admin` |
| `isActive` | `boolean` | Active account flag |
| `isBanned` | `boolean` | Ban flag |
| `fcmTokens` | `array<string>` | Notification tokens |
| `createdAt` | `timestamp` | Creation time |
| `updatedAt` | `timestamp` | Last update |

Current auth trigger defaults:

- `role: customer`
- `isActive: true`
- `isBanned: false`
- `fcmTokens: []`

### Addresses

Subcollection:

- `users/{userId}/addresses/{addressId}`

Current address fields are app-managed and include the usual address details used by the customer profile flows.

### Delivery Vehicle Info

The current delivery profile screen stores vehicle data inside the user document as:

```json
{
  "vehicleInfo": {
    "vehicleType": "Motorcycle",
    "vehicleNumber": "XX-00-AB-1234",
    "licenseNumber": "DL123456"
  }
}
```

### Important Notes

- Older docs used `phoneNumber`; current code uses `phone`.
- Older docs described `favoriteRestaurants`, `notificationPreferences`, `verificationStatus`, `adminLevel`, and `permissions`; those are not part of the core current auth model documented by the app and auth trigger.
- Self-service onboarding currently allows user-side role changes to non-admin roles under the rules flow.

## Restaurants

Collection:

- `restaurants/{restaurantId}`

Current restaurant fields used by the customer restaurant model:

| Field | Type | Notes |
| ----- | ---- | ----- |
| `name` | `string` | Restaurant name |
| `description` | `string` | Description |
| `imageUrl` | `string` | Main image |
| `coverImageUrl` | `string` | Cover image |
| `cuisineTypes` | `array<string>` | Cuisine labels |
| `tags` | `array<string>` | Search/display tags |
| `priceLevel` | `number` | Price tier |
| `isActive` | `boolean` | Visibility flag |
| `isOpen` | `boolean` | Open/closed flag |
| `ownerUid` | `string?` | Restaurant owner user id |
| `preparationTimeMinutes` | `number` | Prep time |
| `minimumOrderAmount` | `number` | Minimum order |
| `deliveryFee` | `number` | Delivery fee |
| `freeDeliveryAbove` | `number` | Free delivery threshold |
| `averageRating` | `number` | Average rating |
| `totalRatings` | `number` | Total ratings |
| `totalOrders` | `number` | Total orders |
| `address` | `map` | `addressLine1`, `city`, `state`, `location` |
| `operatingHours` | `array<map>` | Day/open/close/isClosed |

### Restaurant Subcollections

- `restaurants/{restaurantId}/menuCategories/{categoryId}`
- `restaurants/{restaurantId}/menuItems/{itemId}`

Rules currently allow restaurant owners to manage these when `ownerUid == request.auth.uid`.

## Orders

Collection:

- `orders/{orderId}`

The exact order shape is used across customer, delivery, admin, notifications, earnings, and tracking flows. Important fields referenced by current rules/functions include:

- `customerId`
- `deliveryPartnerId`
- `restaurantId`
- `status`
- `statusHistory`
- `totalAmount`
- `couponCode`
- `actualDeliveryTime`
- `createdAt`
- `updatedAt`

## Delivery Locations

Collection:

- `delivery_locations/{partnerId}`

Used for delivery tracking and driver location updates.

## Chats

Collections:

- `chats/{chatId}`
- `chats/{chatId}/messages/{messageId}`

Chat docs currently depend on:

- `participants`
- message `senderId`
- message `text`
- optional message `imageUrl`

## Earnings

Collection:

- `earnings/{earningsId}`

Fields referenced by current earnings functions include:

- `deliveryPartnerId`
- `deliveryFee`
- `tip`
- `bonus`
- `totalEarned`
- `isPaidOut`
- `date`
- `week`
- `month`

## Promotions

Collection:

- `promotions/{promotionId}`

Fields referenced by pricing and coupon validation include:

- `code`
- `isActive`
- `validUntil`
- `minOrderAmount`
- `maxUses`
- `currentUses`
- `maxUsesPerUser`
- `discountType`
- `discountValue`
- `maxDiscount`

## Notifications

Collection:

- `notifications/{notificationId}`

Current notification documents use fields such as:

- `userId`
- `title`
- `body`
- `type`
- `data`
- `isRead`
- `createdAt`

## App Config

Collection:

- `app_config/{document}`

Current constants reserve `settings` as the main config document id.

## Rules Summary

Current rules enforce:

- users can read their own profile; admins can read any
- users cannot self-promote to `admin`
- self-service role changes are limited to onboarding-compatible roles
- restaurant owners can manage their own restaurants/menu through `ownerUid`
- customers create orders
- delivery partners update only their assigned deliveries
- promotions are admin-managed
