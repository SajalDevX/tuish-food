# Firebase Schema

This document defines the complete Firestore database schema for Tuish Food, including all collections, subcollections, field definitions, composite indexes, and security rules.

---

## Schema Overview

```
Firestore Root
  +-- users/{userId}
  |     +-- addresses/{addressId}
  +-- restaurants/{restaurantId}
  |     +-- menuCategories/{categoryId}
  |     +-- menuItems/{itemId}
  +-- orders/{orderId}
  +-- reviews/{reviewId}
  +-- delivery_locations/{deliveryPartnerId}
  +-- chats/{chatId}
  |     +-- messages/{messageId}
  +-- earnings/{earningsId}
  +-- promotions/{promotionId}
  +-- notifications/{notificationId}
  +-- app_config/settings
```

---

## Collection: `users/{userId}`

Stores all user profiles. The `role` field determines which fields are relevant.

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `uid` | `string` | Yes | Firebase Auth UID (matches document ID) |
| `email` | `string` | Yes | User email address |
| `displayName` | `string` | Yes | Full name |
| `phoneNumber` | `string` | No | Phone number with country code |
| `photoUrl` | `string` | No | Profile photo URL (Firebase Storage) |
| `role` | `string` | Yes | `'customer'` \| `'deliveryPartner'` \| `'admin'` |
| `isActive` | `boolean` | Yes | Whether account is active (false = banned) |
| `fcmTokens` | `array<string>` | No | FCM device tokens for push notifications |
| `notificationPreferences` | `map` | No | `{ orderUpdates: bool, promotions: bool, chat: bool }` |
| `createdAt` | `timestamp` | Yes | Account creation timestamp |
| `updatedAt` | `timestamp` | Yes | Last profile update timestamp |

### Customer-Specific Fields

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `favoriteRestaurants` | `array<string>` | No | List of restaurant IDs |
| `defaultAddressId` | `string` | No | Reference to preferred delivery address |
| `stripeCustomerId` | `string` | No | Stripe customer ID for payments |

### Delivery Partner-Specific Fields

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `vehicleType` | `string` | Yes | `'bicycle'` \| `'motorcycle'` \| `'car'` |
| `vehiclePlate` | `string` | No | License plate number |
| `licenseNumber` | `string` | Yes | Driver's license number |
| `licenseImageUrl` | `string` | Yes | Photo of driver's license (Storage URL) |
| `idDocumentUrl` | `string` | Yes | Photo of government ID (Storage URL) |
| `vehicleDocumentUrl` | `string` | No | Vehicle registration document |
| `verificationStatus` | `string` | Yes | `'pending'` \| `'approved'` \| `'rejected'` |
| `verificationNote` | `string` | No | Admin note on rejection reason |
| `isOnline` | `boolean` | Yes | Currently accepting deliveries |
| `rating` | `number` | Yes | Average rating (1.0-5.0) |
| `totalDeliveries` | `number` | Yes | Lifetime delivery count |
| `totalRatings` | `number` | Yes | Number of ratings received |
| `currentOrderId` | `string` | No | Active delivery order ID (null if free) |
| `lastKnownLocation` | `geopoint` | No | Last reported GPS coordinates |

### Admin-Specific Fields

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `adminLevel` | `string` | Yes | `'superAdmin'` \| `'manager'` \| `'support'` |
| `permissions` | `array<string>` | Yes | List of permission strings |

---

## Subcollection: `users/{userId}/addresses/{addressId}`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `label` | `string` | Yes | `'Home'` \| `'Work'` \| `'Other'` or custom label |
| `addressLine1` | `string` | Yes | Street address |
| `addressLine2` | `string` | No | Apartment, suite, floor |
| `city` | `string` | Yes | City name |
| `state` | `string` | Yes | State or province |
| `postalCode` | `string` | Yes | ZIP or postal code |
| `country` | `string` | Yes | Country code (e.g., `'US'`) |
| `location` | `geopoint` | Yes | Latitude/longitude for map pin |
| `instructions` | `string` | No | Delivery instructions |
| `isDefault` | `boolean` | Yes | Whether this is the default address |
| `createdAt` | `timestamp` | Yes | Creation timestamp |

---

## Collection: `restaurants/{restaurantId}`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `name` | `string` | Yes | Restaurant name |
| `description` | `string` | Yes | Short description |
| `imageUrl` | `string` | Yes | Cover image URL |
| `logoUrl` | `string` | No | Logo image URL |
| `cuisineTypes` | `array<string>` | Yes | E.g., `['Italian', 'Pizza', 'Pasta']` |
| `location` | `geopoint` | Yes | Restaurant coordinates |
| `geohash` | `string` | Yes | Geohash for proximity queries |
| `address` | `map` | Yes | `{ line1, line2, city, state, postalCode, country }` |
| `phoneNumber` | `string` | Yes | Contact phone number |
| `email` | `string` | No | Contact email |
| `rating` | `number` | Yes | Average rating (1.0-5.0), default 0.0 |
| `reviewCount` | `number` | Yes | Total number of reviews, default 0 |
| `priceLevel` | `number` | Yes | 1 (cheap) to 4 (expensive) |
| `deliveryFee` | `number` | Yes | Base delivery fee in cents |
| `minOrderAmount` | `number` | Yes | Minimum order amount in cents |
| `estimatedDeliveryMinutes` | `map` | Yes | `{ min: number, max: number }` |
| `operatingHours` | `map` | Yes | See below |
| `isActive` | `boolean` | Yes | Admin-controlled visibility |
| `isOpen` | `boolean` | Yes | Currently accepting orders |
| `isFeatured` | `boolean` | No | Show in featured/promoted section |
| `tags` | `array<string>` | No | Search tags: `['vegan', 'halal', 'gluten-free']` |
| `createdAt` | `timestamp` | Yes | Creation timestamp |
| `updatedAt` | `timestamp` | Yes | Last update timestamp |

### Operating Hours Format

```json
{
  "monday":    { "open": "09:00", "close": "22:00", "isClosed": false },
  "tuesday":   { "open": "09:00", "close": "22:00", "isClosed": false },
  "wednesday": { "open": "09:00", "close": "22:00", "isClosed": false },
  "thursday":  { "open": "09:00", "close": "22:00", "isClosed": false },
  "friday":    { "open": "09:00", "close": "23:00", "isClosed": false },
  "saturday":  { "open": "10:00", "close": "23:00", "isClosed": false },
  "sunday":    { "open": "10:00", "close": "21:00", "isClosed": false }
}
```

---

## Subcollection: `restaurants/{restaurantId}/menuCategories/{categoryId}`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `name` | `string` | Yes | Category name (e.g., "Appetizers", "Mains") |
| `description` | `string` | No | Category description |
| `imageUrl` | `string` | No | Category image |
| `sortOrder` | `number` | Yes | Display order (ascending) |
| `isActive` | `boolean` | Yes | Whether category is visible |

---

## Subcollection: `restaurants/{restaurantId}/menuItems/{itemId}`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `name` | `string` | Yes | Item name |
| `description` | `string` | Yes | Item description |
| `imageUrl` | `string` | No | Item photo URL |
| `categoryId` | `string` | Yes | Reference to parent category |
| `price` | `number` | Yes | Base price in cents |
| `discountedPrice` | `number` | No | Sale price in cents (null = no discount) |
| `isAvailable` | `boolean` | Yes | Currently orderable |
| `isVegetarian` | `boolean` | No | Vegetarian flag |
| `isVegan` | `boolean` | No | Vegan flag |
| `isGlutenFree` | `boolean` | No | Gluten-free flag |
| `spiceLevel` | `number` | No | 0 (none) to 3 (very spicy) |
| `preparationTime` | `number` | No | Estimated prep time in minutes |
| `calories` | `number` | No | Calorie count |
| `tags` | `array<string>` | No | `['popular', 'new', 'chef-special']` |
| `customizations` | `array<map>` | No | See below |
| `sortOrder` | `number` | Yes | Display order within category |
| `createdAt` | `timestamp` | Yes | Creation timestamp |
| `updatedAt` | `timestamp` | Yes | Last update timestamp |

### Customizations Array Format

Each element in `customizations` is a customization group:

```json
{
  "id": "size_001",
  "name": "Size",
  "type": "single",
  "required": true,
  "minSelections": 1,
  "maxSelections": 1,
  "options": [
    { "id": "opt_s", "name": "Small", "priceAdjustment": 0 },
    { "id": "opt_m", "name": "Medium", "priceAdjustment": 200 },
    { "id": "opt_l", "name": "Large", "priceAdjustment": 400 }
  ]
}
```

| Customization Field | Type | Description |
| ------------------- | ---- | ----------- |
| `id` | `string` | Unique ID within the item |
| `name` | `string` | Group label ("Size", "Toppings", "Extras") |
| `type` | `string` | `'single'` (radio) or `'multiple'` (checkbox) |
| `required` | `boolean` | Must select at least one option |
| `minSelections` | `number` | Minimum selections (for `multiple`) |
| `maxSelections` | `number` | Maximum selections (for `multiple`) |
| `options` | `array<map>` | Available options |
| `options[].id` | `string` | Unique option ID |
| `options[].name` | `string` | Option label |
| `options[].priceAdjustment` | `number` | Price delta in cents (can be 0 or negative) |

---

## Collection: `orders/{orderId}`

Orders are denormalized for read performance. All relevant data is embedded at creation time.

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `orderNumber` | `string` | Yes | Human-readable order number (e.g., `TF-20260328-A1B2`) |
| `customerId` | `string` | Yes | Customer UID |
| `customerName` | `string` | Yes | Denormalized customer name |
| `customerPhone` | `string` | Yes | Denormalized customer phone |
| `deliveryPartnerId` | `string` | No | Assigned delivery partner UID (null until assigned) |
| `deliveryPartnerName` | `string` | No | Denormalized partner name |
| `restaurantId` | `string` | Yes | Restaurant document ID |
| `restaurantName` | `string` | Yes | Denormalized restaurant name |
| `restaurantLocation` | `geopoint` | Yes | Denormalized restaurant coordinates |
| `restaurantPhone` | `string` | Yes | Denormalized restaurant phone |
| `status` | `string` | Yes | See Order Status enum below |
| `items` | `array<map>` | Yes | See Order Items below |
| `deliveryAddress` | `map` | Yes | Full address snapshot (same shape as addresses subcollection) |
| `specialInstructions` | `string` | No | Customer note to restaurant |
| `pricing` | `map` | Yes | See Pricing Breakdown below |
| `paymentMethod` | `string` | Yes | `'card'` \| `'cash'` |
| `paymentStatus` | `string` | Yes | `'pending'` \| `'paid'` \| `'failed'` \| `'refunded'` |
| `stripePaymentIntentId` | `string` | No | Stripe PaymentIntent ID |
| `couponCode` | `string` | No | Applied coupon code |
| `statusHistory` | `array<map>` | Yes | See Status History below |
| `estimatedDeliveryTime` | `timestamp` | No | ETA for delivery |
| `actualDeliveryTime` | `timestamp` | No | When delivery was completed |
| `cancellationReason` | `string` | No | If cancelled, the reason |
| `cancelledBy` | `string` | No | `'customer'` \| `'restaurant'` \| `'admin'` \| `'system'` |
| `chatId` | `string` | No | Reference to chat document |
| `customerRated` | `boolean` | Yes | Whether customer has submitted rating |
| `createdAt` | `timestamp` | Yes | Order placement timestamp |
| `updatedAt` | `timestamp` | Yes | Last status change |

### Order Status Enum

```
placed -> confirmed -> preparing -> readyForPickup -> pickedUp -> delivered
                                                              \-> cancelled
placed -> cancelled (customer cancel before confirmation)
confirmed -> cancelled (restaurant cancel)
```

| Status | Description |
| ------ | ----------- |
| `placed` | Order placed by customer, awaiting restaurant confirmation |
| `confirmed` | Restaurant accepted the order |
| `preparing` | Restaurant is preparing the food |
| `readyForPickup` | Food ready, awaiting delivery partner |
| `pickedUp` | Delivery partner picked up the order |
| `delivered` | Order delivered to customer |
| `cancelled` | Order cancelled |

### Order Items Array

```json
[
  {
    "itemId": "menu_item_123",
    "name": "Margherita Pizza",
    "imageUrl": "https://...",
    "quantity": 2,
    "basePrice": 1299,
    "customizations": [
      {
        "groupId": "size_001",
        "groupName": "Size",
        "selectedOptions": [
          { "id": "opt_l", "name": "Large", "priceAdjustment": 400 }
        ]
      }
    ],
    "totalPrice": 3398,
    "specialInstructions": "Extra crispy"
  }
]
```

### Pricing Breakdown

```json
{
  "subtotal": 3398,
  "deliveryFee": 499,
  "serviceFee": 199,
  "tax": 306,
  "tip": 500,
  "discount": 0,
  "total": 4902
}
```

All amounts are in **cents** (integer) to avoid floating-point issues.

### Status History

```json
[
  { "status": "placed",         "timestamp": "2026-03-28T10:00:00Z", "note": null },
  { "status": "confirmed",      "timestamp": "2026-03-28T10:02:00Z", "note": null },
  { "status": "preparing",      "timestamp": "2026-03-28T10:03:00Z", "note": null },
  { "status": "readyForPickup", "timestamp": "2026-03-28T10:18:00Z", "note": null },
  { "status": "pickedUp",       "timestamp": "2026-03-28T10:22:00Z", "note": "Delivery partner: John D." },
  { "status": "delivered",      "timestamp": "2026-03-28T10:38:00Z", "note": null }
]
```

---

## Collection: `reviews/{reviewId}`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `orderId` | `string` | Yes | Associated order ID |
| `reviewerId` | `string` | Yes | Customer UID who wrote the review |
| `reviewerName` | `string` | Yes | Denormalized reviewer name |
| `reviewerPhotoUrl` | `string` | No | Denormalized reviewer photo |
| `targetId` | `string` | Yes | Restaurant ID or delivery partner UID |
| `targetType` | `string` | Yes | `'restaurant'` \| `'deliveryPartner'` |
| `overallRating` | `number` | Yes | 1.0 to 5.0 (0.5 increments) |
| `subRatings` | `map` | No | See below |
| `comment` | `string` | No | Written review text |
| `imageUrls` | `array<string>` | No | Review photos (up to 3) |
| `isVisible` | `boolean` | Yes | Admin can hide inappropriate reviews |
| `createdAt` | `timestamp` | Yes | Review creation timestamp |
| `updatedAt` | `timestamp` | Yes | Last edit timestamp |

### Sub-Ratings by Target Type

**Restaurant reviews:**
```json
{
  "foodQuality": 4.5,
  "portionSize": 4.0,
  "valueForMoney": 3.5,
  "packaging": 4.0
}
```

**Delivery partner reviews:**
```json
{
  "speed": 5.0,
  "communication": 4.5,
  "foodCondition": 5.0
}
```

---

## Collection: `delivery_locations/{deliveryPartnerId}`

A **separate hot-path collection** optimized for frequent GPS writes. Kept outside `users` to avoid triggering unnecessary reads/listeners on the user document.

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `location` | `geopoint` | Yes | Current GPS coordinates |
| `geohash` | `string` | Yes | Geohash for proximity queries (precision 6) |
| `heading` | `number` | No | Compass heading in degrees (0-360) |
| `speed` | `number` | No | Speed in m/s |
| `accuracy` | `number` | No | GPS accuracy in meters |
| `isOnline` | `boolean` | Yes | Mirror of user's online status |
| `currentOrderId` | `string` | No | Active order being delivered |
| `vehicleType` | `string` | Yes | For filtering and icon display |
| `updatedAt` | `timestamp` | Yes | Last location update |

**Write frequency:** Every 5 seconds during active delivery, every 15 seconds when online but idle.

---

## Collection: `chats/{chatId}`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `orderId` | `string` | Yes | Associated order ID |
| `participants` | `array<string>` | Yes | UIDs of customer and delivery partner |
| `participantNames` | `map` | Yes | `{ "uid1": "John", "uid2": "Jane" }` |
| `lastMessage` | `map` | No | `{ text, senderId, timestamp }` for preview |
| `unreadCount` | `map` | Yes | `{ "uid1": 0, "uid2": 2 }` per-user unread count |
| `isActive` | `boolean` | Yes | False after order completed (read-only) |
| `createdAt` | `timestamp` | Yes | Chat creation timestamp |

### Subcollection: `chats/{chatId}/messages/{messageId}`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `senderId` | `string` | Yes | Sender UID |
| `senderName` | `string` | Yes | Denormalized sender name |
| `text` | `string` | No | Message text (required if no imageUrl) |
| `imageUrl` | `string` | No | Image message URL |
| `type` | `string` | Yes | `'text'` \| `'image'` \| `'system'` |
| `isRead` | `boolean` | Yes | Read receipt |
| `createdAt` | `timestamp` | Yes | Send timestamp |

---

## Collection: `earnings/{earningsId}`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `deliveryPartnerId` | `string` | Yes | Delivery partner UID |
| `orderId` | `string` | Yes | Associated order ID |
| `orderNumber` | `string` | Yes | Denormalized order number |
| `deliveryFee` | `number` | Yes | Delivery fee earned (cents) |
| `tip` | `number` | Yes | Tip amount (cents) |
| `bonus` | `number` | No | Any bonus amount (cents) |
| `totalEarning` | `number` | Yes | Sum of all earnings (cents) |
| `status` | `string` | Yes | `'pending'` \| `'processed'` \| `'paid'` |
| `payoutId` | `string` | No | Reference to payout batch |
| `date` | `timestamp` | Yes | Date of the earning |
| `createdAt` | `timestamp` | Yes | Record creation timestamp |

---

## Collection: `promotions/{promotionId}`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `code` | `string` | Yes | Coupon code (uppercase, unique) |
| `description` | `string` | Yes | Human-readable description |
| `discountType` | `string` | Yes | `'percentage'` \| `'fixedAmount'` |
| `discountValue` | `number` | Yes | Percentage (e.g., 20) or amount in cents |
| `minOrderAmount` | `number` | No | Minimum order subtotal in cents |
| `maxDiscountAmount` | `number` | No | Cap for percentage discounts (cents) |
| `applicableRestaurants` | `array<string>` | No | Restrict to specific restaurants (empty = all) |
| `usageLimit` | `number` | No | Total uses allowed (null = unlimited) |
| `usageCount` | `number` | Yes | Current total uses |
| `perUserLimit` | `number` | Yes | Max uses per customer (default 1) |
| `usedBy` | `map` | Yes | `{ "userId": usageCount }` tracking per-user usage |
| `startDate` | `timestamp` | Yes | Promotion start date |
| `endDate` | `timestamp` | Yes | Promotion end date |
| `isActive` | `boolean` | Yes | Admin toggle |
| `createdAt` | `timestamp` | Yes | Creation timestamp |

---

## Collection: `notifications/{notificationId}`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `userId` | `string` | Yes | Recipient UID |
| `title` | `string` | Yes | Notification title |
| `body` | `string` | Yes | Notification body text |
| `type` | `string` | Yes | `'orderUpdate'` \| `'newOrder'` \| `'chat'` \| `'promotion'` \| `'earnings'` \| `'system'` |
| `data` | `map` | No | Payload for deep linking: `{ orderId, chatId, screen, ... }` |
| `imageUrl` | `string` | No | Rich notification image |
| `isRead` | `boolean` | Yes | Whether notification has been read |
| `createdAt` | `timestamp` | Yes | Creation timestamp |

---

## Singleton Document: `app_config/settings`

A single document holding global application configuration, editable by admins.

| Field | Type | Description |
| ----- | ---- | ----------- |
| `serviceFeePercentage` | `number` | Service fee as percentage (e.g., 5.0 = 5%) |
| `serviceFeeMin` | `number` | Minimum service fee in cents |
| `serviceFeeMax` | `number` | Maximum service fee in cents |
| `defaultDeliveryFee` | `number` | Default delivery fee in cents |
| `deliveryFeePerKm` | `number` | Additional fee per km in cents |
| `maxDeliveryRadiusKm` | `number` | Maximum delivery radius in km |
| `taxPercentage` | `number` | Tax rate (e.g., 8.25) |
| `minOrderAmount` | `number` | Global minimum order in cents |
| `currentAppVersion` | `string` | Latest app version (e.g., `"1.2.0"`) |
| `forceUpdateVersion` | `string` | Minimum required version (force update below this) |
| `maintenanceMode` | `boolean` | If true, show maintenance screen |
| `maintenanceMessage` | `string` | Message to display during maintenance |
| `supportEmail` | `string` | Customer support email |
| `supportPhone` | `string` | Customer support phone |
| `termsUrl` | `string` | Terms of service URL |
| `privacyUrl` | `string` | Privacy policy URL |
| `deliveryPartnerPayoutDay` | `string` | Day of week for payouts (e.g., `'monday'`) |

---

## Composite Indexes

Firestore requires composite indexes for queries with multiple conditions or ordering.

| Collection | Fields | Query Purpose |
| ---------- | ------ | ------------- |
| `orders` | `customerId` ASC, `createdAt` DESC | Customer order history |
| `orders` | `deliveryPartnerId` ASC, `createdAt` DESC | Delivery partner order history |
| `orders` | `restaurantId` ASC, `createdAt` DESC | Restaurant order history |
| `orders` | `status` ASC, `createdAt` DESC | Filter orders by status |
| `orders` | `restaurantId` ASC, `status` ASC, `createdAt` DESC | Admin: orders for restaurant by status |
| `reviews` | `targetId` ASC, `targetType` ASC, `createdAt` DESC | Reviews for a restaurant/partner |
| `reviews` | `reviewerId` ASC, `createdAt` DESC | User's review history |
| `delivery_locations` | `isOnline` ASC, `geohash` ASC | Find nearby online delivery partners |
| `earnings` | `deliveryPartnerId` ASC, `date` DESC | Partner earnings history |
| `earnings` | `deliveryPartnerId` ASC, `status` ASC | Pending payouts for a partner |
| `notifications` | `userId` ASC, `createdAt` DESC | User notification feed |
| `notifications` | `userId` ASC, `isRead` ASC, `createdAt` DESC | Unread notifications |
| `promotions` | `isActive` ASC, `endDate` ASC | Active valid promotions |

### Index Definition File (`firestore.indexes.json`)

```json
{
  "indexes": [
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "customerId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "deliveryPartnerId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "targetId", "order": "ASCENDING" },
        { "fieldPath": "targetType", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "delivery_locations",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isOnline", "order": "ASCENDING" },
        { "fieldPath": "geohash", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "earnings",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "deliveryPartnerId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

## Security Rules Overview

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    function hasRole(role) {
      return isAuthenticated() && request.auth.token.role == role;
    }

    function isAdmin() {
      return hasRole('admin');
    }

    function isDeliveryPartner() {
      return hasRole('deliveryPartner');
    }

    function isCustomer() {
      return hasRole('customer');
    }

    // Users
    match /users/{userId} {
      allow read: if isOwner(userId) || isAdmin();
      allow create: if isOwner(userId);
      allow update: if isOwner(userId) || isAdmin();
      allow delete: if isAdmin();

      match /addresses/{addressId} {
        allow read, write: if isOwner(userId);
      }
    }

    // Restaurants (public read, admin write)
    match /restaurants/{restaurantId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();

      match /menuCategories/{categoryId} {
        allow read: if isAuthenticated();
        allow write: if isAdmin();
      }

      match /menuItems/{itemId} {
        allow read: if isAuthenticated();
        allow write: if isAdmin();
      }
    }

    // Orders
    match /orders/{orderId} {
      allow read: if isAdmin()
        || resource.data.customerId == request.auth.uid
        || resource.data.deliveryPartnerId == request.auth.uid;
      allow create: if isCustomer();
      allow update: if isAdmin()
        || (isCustomer() && resource.data.customerId == request.auth.uid)
        || (isDeliveryPartner() && resource.data.deliveryPartnerId == request.auth.uid);
      allow delete: if false; // Orders are never deleted
    }

    // Reviews
    match /reviews/{reviewId} {
      allow read: if isAuthenticated();
      allow create: if isCustomer();
      allow update: if resource.data.reviewerId == request.auth.uid || isAdmin();
      allow delete: if isAdmin();
    }

    // Delivery Locations (hot path)
    match /delivery_locations/{partnerId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(partnerId);
    }

    // Chats
    match /chats/{chatId} {
      allow read: if request.auth.uid in resource.data.participants;
      allow create: if false; // Created by Cloud Functions only
      allow update: if request.auth.uid in resource.data.participants;

      match /messages/{messageId} {
        allow read: if request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
        allow create: if request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
      }
    }

    // Earnings (partner reads own, admin reads all)
    match /earnings/{earningsId} {
      allow read: if resource.data.deliveryPartnerId == request.auth.uid || isAdmin();
      allow write: if false; // Written by Cloud Functions only
    }

    // Promotions (public read, admin write)
    match /promotions/{promotionId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }

    // Notifications
    match /notifications/{notificationId} {
      allow read: if resource.data.userId == request.auth.uid;
      allow update: if resource.data.userId == request.auth.uid; // Mark as read
      allow create, delete: if false; // Cloud Functions only
    }

    // App Config (public read, admin write)
    match /app_config/{document} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
  }
}
```

---

## Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // User profile photos
    match /users/{userId}/profile/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId
        && request.resource.size < 5 * 1024 * 1024  // 5MB
        && request.resource.contentType.matches('image/.*');
    }

    // Delivery partner documents (private)
    match /users/{userId}/documents/{fileName} {
      allow read: if request.auth.uid == userId
        || request.auth.token.role == 'admin';
      allow write: if request.auth.uid == userId
        && request.resource.size < 10 * 1024 * 1024;  // 10MB
    }

    // Restaurant images (admin only write)
    match /restaurants/{restaurantId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth.token.role == 'admin'
        && request.resource.size < 10 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }

    // Review photos
    match /reviews/{reviewId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && request.resource.size < 5 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }

    // Chat images
    match /chats/{chatId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && request.resource.size < 5 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }
  }
}
```
