# API Contracts

This document defines all Firebase Cloud Functions for Tuish Food, including their triggers, request/response types, error codes, and authentication requirements.

---

## Overview

All Cloud Functions are written in TypeScript and deployed to Firebase Cloud Functions (2nd gen where applicable). Functions are organized by trigger type:

| Type | Count | Description |
| ---- | ----- | ----------- |
| Auth Triggers | 2 | Respond to user creation/deletion |
| Callable Functions | 6 | Client-invoked via `httpsCallable` |
| Firestore Triggers | 5 | Respond to document changes |
| Scheduled Functions | 4 | Run on cron schedules |

---

## Common Types

```typescript
// Shared interfaces used across functions

interface ApiResponse<T = void> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}

interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

type UserRole = 'customer' | 'deliveryPartner' | 'admin';

type OrderStatus =
  | 'placed'
  | 'confirmed'
  | 'preparing'
  | 'readyForPickup'
  | 'pickedUp'
  | 'delivered'
  | 'cancelled';

type PaymentStatus = 'pending' | 'paid' | 'failed' | 'refunded';

interface GeoPoint {
  latitude: number;
  longitude: number;
}

interface PriceBreakdown {
  subtotal: number;      // cents
  deliveryFee: number;   // cents
  serviceFee: number;    // cents
  tax: number;           // cents
  tip: number;           // cents
  discount: number;      // cents
  total: number;         // cents
}
```

---

## Auth Triggers

### `onUserCreated`

**Trigger:** `functions.auth.user().onCreate()`

Fires when a new Firebase Auth user is created. Sets default custom claims and creates the initial Firestore user document.

```typescript
// Trigger: Auth user creation
// Auth Required: N/A (system trigger)

// Behavior:
// 1. Set custom claim: { role: 'customer' }
// 2. Create users/{uid} document with default fields
// 3. Log creation event

interface UserDocument {
  uid: string;
  email: string | null;
  displayName: string | null;
  phoneNumber: string | null;
  photoUrl: string | null;
  role: 'customer';
  isActive: true;
  fcmTokens: [];
  notificationPreferences: {
    orderUpdates: true;
    promotions: true;
    chat: true;
  };
  favoriteRestaurants: [];
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}
```

### `onUserDeleted`

**Trigger:** `functions.auth.user().onDelete()`

Fires when a Firebase Auth user is deleted. Cleans up all associated data.

```typescript
// Trigger: Auth user deletion
// Auth Required: N/A (system trigger)

// Behavior:
// 1. Delete users/{uid} document and subcollections (addresses)
// 2. Delete delivery_locations/{uid} (if delivery partner)
// 3. Delete user's files from Firebase Storage
// 4. Cancel any active orders (set to 'cancelled')
// 5. Delete user's notifications
// 6. Remove user from chat participants
// 7. Delete Stripe customer (if exists)
// 8. Clean up earnings records (mark as orphaned)
```

---

## Callable Functions

### `setUserRole`

Sets a user's role via custom claims. Admin-only.

```typescript
// Auth Required: Admin role
// Rate Limit: 10 calls/minute per admin

interface SetUserRoleRequest {
  userId: string;
  role: UserRole;
}

interface SetUserRoleResponse {
  success: boolean;
  previousRole: UserRole;
  newRole: UserRole;
}

// Error Codes:
// 'permission-denied'   - Caller is not an admin
// 'invalid-argument'    - Invalid role value or missing userId
// 'not-found'           - User does not exist
// 'failed-precondition' - Delivery partner not in 'pending' verification status
```

**Example call from Flutter:**

```dart
final callable = FirebaseFunctions.instance.httpsCallable('setUserRole');
final result = await callable.call({
  'userId': 'abc123',
  'role': 'deliveryPartner',
});
```

---

### `calculateFees`

Calculates the complete price breakdown for an order. Called during checkout to ensure server-side pricing integrity.

```typescript
// Auth Required: Any authenticated user
// Rate Limit: 30 calls/minute per user

interface CalculateFeesRequest {
  restaurantId: string;
  items: Array<{
    itemId: string;
    quantity: number;
    customizations: Array<{
      groupId: string;
      selectedOptionIds: string[];
    }>;
  }>;
  deliveryAddress: {
    location: GeoPoint;
  };
  couponCode?: string;
  tip?: number;  // cents
}

interface CalculateFeesResponse {
  pricing: PriceBreakdown;
  deliveryDistanceKm: number;
  estimatedDeliveryMinutes: {
    min: number;
    max: number;
  };
  couponApplied: boolean;
  couponDiscount: number;  // cents
  couponError?: string;    // if coupon invalid
}

// Error Codes:
// 'not-found'           - Restaurant or menu item not found
// 'failed-precondition' - Restaurant is closed or inactive
// 'invalid-argument'    - Invalid items, missing required customizations
// 'out-of-range'        - Delivery address outside max delivery radius
```

**Server-side calculation logic:**

```typescript
// 1. Fetch restaurant and verify it's open
// 2. Fetch all menu items and validate they exist and are available
// 3. Calculate subtotal from items with customizations
// 4. Calculate delivery fee: base + (distance * perKmRate)
// 5. Calculate service fee: max(min, min(max, subtotal * percentage))
// 6. Calculate tax: subtotal * taxPercentage
// 7. Validate and apply coupon (if provided)
// 8. Calculate total: subtotal + deliveryFee + serviceFee + tax + tip - discount
```

---

### `validateCoupon`

Validates a coupon code without calculating full fees. Used for real-time validation in the cart.

```typescript
// Auth Required: Any authenticated user (customer)
// Rate Limit: 20 calls/minute per user

interface ValidateCouponRequest {
  couponCode: string;
  restaurantId: string;
  subtotal: number;  // cents
}

interface ValidateCouponResponse {
  isValid: boolean;
  discountType?: 'percentage' | 'fixedAmount';
  discountValue?: number;
  estimatedDiscount?: number;  // cents
  error?: string;
}

// Error Codes:
// 'not-found'           - Coupon code does not exist
// 'failed-precondition' - Coupon expired, inactive, or usage limit reached
// 'invalid-argument'    - Order below minimum amount for this coupon
// 'permission-denied'   - User has exceeded per-user usage limit
```

**Validation checks (in order):**

1. Coupon exists
2. Coupon is active (`isActive == true`)
3. Current date is within start/end date range
4. Total usage count < usage limit (if set)
5. Per-user usage count < per-user limit
6. Restaurant is in `applicableRestaurants` (if restricted)
7. Subtotal >= `minOrderAmount` (if set)

---

### `getDashboardStats`

Returns aggregated statistics for the admin dashboard.

```typescript
// Auth Required: Admin role
// Rate Limit: 10 calls/minute per admin
// Caching: Results cached for 5 minutes server-side

interface GetDashboardStatsRequest {
  dateRange: 'today' | '7days' | '30days' | '90days' | '1year';
}

interface GetDashboardStatsResponse {
  kpis: {
    totalOrders: number;
    totalOrdersChange: number;         // percentage change vs previous period
    revenue: number;                   // cents
    revenueChange: number;             // percentage change
    activeUsers: number;
    avgDeliveryTimeMinutes: number;
    avgDeliveryTimeChange: number;     // change in minutes
  };
  revenueChart: Array<{
    date: string;          // ISO date
    totalRevenue: number;  // cents
    deliveryFees: number;  // cents
    serviceFees: number;   // cents
  }>;
  orderTrends: Array<{
    date: string;
    placed: number;
    delivered: number;
    cancelled: number;
  }>;
  recentActivity: Array<{
    type: 'order' | 'delivery' | 'application' | 'refund' | 'restaurant';
    message: string;
    timestamp: string;
    metadata: Record<string, any>;
  }>;
}

// Error Codes:
// 'permission-denied' - Caller is not an admin
```

---

### `getRevenueReport`

Generates a detailed revenue report for export.

```typescript
// Auth Required: Admin role
// Rate Limit: 5 calls/minute per admin

interface GetRevenueReportRequest {
  startDate: string;  // ISO date
  endDate: string;    // ISO date
  groupBy: 'day' | 'week' | 'month';
  restaurantId?: string;  // optional filter
}

interface GetRevenueReportResponse {
  periods: Array<{
    periodStart: string;
    periodEnd: string;
    orderCount: number;
    subtotal: number;
    deliveryFees: number;
    serviceFees: number;
    tax: number;
    tips: number;
    discounts: number;
    refunds: number;
    netRevenue: number;
  }>;
  totals: {
    orderCount: number;
    subtotal: number;
    deliveryFees: number;
    serviceFees: number;
    tax: number;
    tips: number;
    discounts: number;
    refunds: number;
    netRevenue: number;
  };
}

// Error Codes:
// 'permission-denied' - Caller is not an admin
// 'invalid-argument'  - Invalid date range or groupBy value
// 'out-of-range'      - Date range exceeds 1 year
```

---

### `getEarningsSummary`

Returns earnings summary for a delivery partner.

```typescript
// Auth Required: Delivery partner (own data) or Admin (any partner)
// Rate Limit: 20 calls/minute per user

interface GetEarningsSummaryRequest {
  deliveryPartnerId?: string;  // Admin only, defaults to caller
  period: 'today' | 'week' | 'month' | 'custom';
  startDate?: string;  // Required if period == 'custom'
  endDate?: string;    // Required if period == 'custom'
}

interface GetEarningsSummaryResponse {
  totalEarnings: number;      // cents
  deliveryFees: number;       // cents
  tips: number;               // cents
  bonuses: number;            // cents
  deliveryCount: number;
  averagePerDelivery: number; // cents
  dailyBreakdown: Array<{
    date: string;
    earnings: number;
    deliveryFees: number;
    tips: number;
    bonuses: number;
    deliveryCount: number;
  }>;
  pendingPayout: number;  // cents not yet paid out
}

// Error Codes:
// 'permission-denied' - Not the partner or not an admin
// 'invalid-argument'  - Invalid period or missing dates for custom period
```

---

## Firestore Triggers

### `onOrderCreated`

**Trigger:** `functions.firestore.document('orders/{orderId}').onCreate()`

Fires when a new order document is created.

```typescript
// Behavior:
// 1. Generate human-readable orderNumber (TF-YYYYMMDD-XXXX)
// 2. Validate order data integrity
// 3. Create chat document for customer-partner communication
// 4. Send push notification to restaurant (future: dashboard notification)
// 5. Begin delivery partner assignment process:
//    a. Query delivery_locations for online partners near restaurant
//    b. Filter by geohash range
//    c. Calculate Haversine distance
//    d. Sort by distance (then by rating for ties)
//    e. Send notification to nearest partner
//    f. Set 30-second timeout for acceptance
// 6. Create notification document for customer ("Order placed")
// 7. Update daily aggregation counters (for dashboard)
```

---

### `onOrderUpdated`

**Trigger:** `functions.firestore.document('orders/{orderId}').onUpdate()`

Fires when an order document is modified.

```typescript
// Checks what changed and acts accordingly:

interface OrderChange {
  before: OrderDocument;
  after: OrderDocument;
}

// Status change handling:
// 'placed' -> 'confirmed':
//   - Notify customer: "Your order has been confirmed!"
//
// 'confirmed' -> 'preparing':
//   - Notify customer: "Your order is being prepared"
//
// 'preparing' -> 'readyForPickup':
//   - Notify delivery partner: "Order is ready for pickup"
//   - Notify customer: "Your order is ready for pickup"
//
// 'readyForPickup' -> 'pickedUp':
//   - Notify customer: "Your order is on the way!"
//   - Start real-time tracking (customer can now see driver location)
//
// 'pickedUp' -> 'delivered':
//   - Handled by onDeliveryCompleted trigger
//
// Any -> 'cancelled':
//   - If paymentStatus == 'paid', initiate Stripe refund
//   - Notify affected parties
//   - Free up delivery partner (clear currentOrderId)
//   - Update daily aggregation counters
//
// deliveryPartnerId change (partner assigned):
//   - Notify customer: "A delivery partner has been assigned"
//   - Set partner's currentOrderId
//   - Create chat document (if not exists)
```

---

### `onReviewCreated`

**Trigger:** `functions.firestore.document('reviews/{reviewId}').onCreate()`

Updates aggregate ratings when a new review is created.

```typescript
// Behavior:
// 1. Determine target type (restaurant or deliveryPartner)
// 2. Read current rating and count from target document
// 3. Calculate new running average:
//    newRating = ((oldRating * oldCount) + newReviewRating) / (oldCount + 1)
// 4. Update target document:
//    - restaurant: { rating, reviewCount }
//    - delivery partner: { rating, totalRatings }
// 5. Mark order as customerRated: true

// Running average calculation:
function updateRating(
  currentRating: number,
  currentCount: number,
  newRating: number
): { rating: number; count: number } {
  const newCount = currentCount + 1;
  const updatedRating = ((currentRating * currentCount) + newRating) / newCount;
  return {
    rating: Math.round(updatedRating * 10) / 10,  // 1 decimal place
    count: newCount,
  };
}
```

---

### `onReviewDeleted`

**Trigger:** `functions.firestore.document('reviews/{reviewId}').onDelete()`

Recalculates aggregate ratings when a review is removed (by admin).

```typescript
// Behavior:
// 1. Read the deleted review's rating and target
// 2. Read current rating and count from target
// 3. Reverse the running average:
//    newRating = ((oldRating * oldCount) - deletedRating) / (oldCount - 1)
//    Handle edge case: if oldCount == 1, set rating to 0
// 4. Update target document with new rating and decremented count
```

---

### `onDeliveryCompleted`

**Trigger:** Firestore trigger on order status change to `delivered`, or separate function called from `onOrderUpdated`.

```typescript
// Behavior:
// 1. Set actualDeliveryTime on order
// 2. Create earnings record:
//    {
//      deliveryPartnerId: order.deliveryPartnerId,
//      orderId: order.id,
//      orderNumber: order.orderNumber,
//      deliveryFee: order.pricing.deliveryFee,
//      tip: order.pricing.tip,
//      bonus: 0, // calculated based on rules
//      totalEarning: deliveryFee + tip + bonus,
//      status: 'pending',
//      date: now,
//    }
// 3. Clear delivery partner's currentOrderId
// 4. Notify customer: "Your order has been delivered!"
// 5. Notify customer: prompt to rate (after 5-minute delay via scheduled task)
// 6. Update daily aggregation counters
// 7. Calculate delivery time and update restaurant's estimated times
```

---

## Scheduled Functions

### `dailyAggregation`

**Schedule:** Every day at 00:05 UTC

Aggregates the previous day's data for dashboard performance.

```typescript
// Schedule: 0 5 0 * * * (daily at 00:05)
// Auth Required: N/A (system)

// Behavior:
// 1. Query all orders from previous day
// 2. Calculate: total orders, revenue, avg delivery time,
//    cancellation rate, popular restaurants, peak hours
// 3. Store in aggregations/daily/{date} document
// 4. Update running monthly and yearly totals
// 5. Generate alerts if metrics fall outside thresholds:
//    - Cancellation rate > 10%
//    - Avg delivery time > 45 min
//    - Revenue drop > 20% vs same day last week
```

---

### `processPayouts`

**Schedule:** Weekly (configurable day from `app_config`)

Processes pending earnings into payouts for delivery partners.

```typescript
// Schedule: 0 0 2 * * MON (every Monday at 02:00, configurable)
// Auth Required: N/A (system)

// Behavior:
// 1. Read payout day from app_config/settings
// 2. Query all earnings where status == 'pending'
// 3. Group by deliveryPartnerId
// 4. For each partner:
//    a. Sum all pending earnings
//    b. Create payout record:
//       {
//         partnerId: string,
//         amount: number,
//         earningsIds: string[],
//         status: 'processing',
//         periodStart: date,
//         periodEnd: date,
//       }
//    c. Update all included earnings to status: 'processed'
//    d. (Future: trigger Stripe Connect transfer)
//    e. Send notification to partner: "Payout of $X.XX is being processed"
// 5. Mark payouts as 'paid' after transfer confirmation
```

---

### `expirePromotions`

**Schedule:** Every hour

Deactivates promotions that have passed their end date.

```typescript
// Schedule: 0 0 * * * * (every hour)
// Auth Required: N/A (system)

// Behavior:
// 1. Query promotions where isActive == true AND endDate < now
// 2. Batch update: set isActive = false
// 3. Log expired promotion codes
```

---

### `cleanupOldLocations`

**Schedule:** Every 6 hours

Removes stale delivery location data from partners who went offline without properly cleaning up.

```typescript
// Schedule: 0 0 */6 * * * (every 6 hours)
// Auth Required: N/A (system)

// Behavior:
// 1. Query delivery_locations where updatedAt < (now - 2 hours)
//    AND isOnline == true
// 2. For each stale location:
//    a. Set isOnline = false
//    b. Update corresponding user document: isOnline = false
//    c. If currentOrderId exists, alert admin (stuck order)
// 3. Delete delivery_locations where updatedAt < (now - 7 days)
//    AND isOnline == false (cleanup old offline records)
```

---

## Error Codes Reference

| Code | HTTP Status | Description |
| ---- | ----------- | ----------- |
| `ok` | 200 | Success |
| `invalid-argument` | 400 | Invalid request data |
| `failed-precondition` | 400 | Operation not allowed in current state |
| `not-found` | 404 | Requested resource does not exist |
| `already-exists` | 409 | Resource already exists (e.g., duplicate coupon code) |
| `permission-denied` | 403 | Caller lacks required role or permission |
| `unauthenticated` | 401 | No valid auth token provided |
| `resource-exhausted` | 429 | Rate limit exceeded |
| `internal` | 500 | Unexpected server error |
| `unavailable` | 503 | Service temporarily unavailable |
| `out-of-range` | 400 | Value outside acceptable range (e.g., delivery too far) |

---

## Rate Limiting

All callable functions enforce rate limits using Firebase's built-in rate limiting and custom checks:

| Function | Limit | Window |
| -------- | ----- | ------ |
| `setUserRole` | 10 calls | per minute per admin |
| `calculateFees` | 30 calls | per minute per user |
| `validateCoupon` | 20 calls | per minute per user |
| `getDashboardStats` | 10 calls | per minute per admin |
| `getRevenueReport` | 5 calls | per minute per admin |
| `getEarningsSummary` | 20 calls | per minute per user |

---

## Deployment

```bash
# Deploy all functions
firebase deploy --only functions

# Deploy a specific function
firebase deploy --only functions:onOrderCreated

# Deploy a group
firebase deploy --only functions:auth,functions:orders

# View logs
firebase functions:log --only onOrderCreated
```
