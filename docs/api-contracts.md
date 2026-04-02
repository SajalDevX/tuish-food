# API Contracts

This document describes the Cloud Functions currently exported by the codebase.

## Source Of Truth

- Entry point: `functions/src/index.ts`
- Shared role/status constants: `functions/src/utils/constants.ts`

## Exported Functions

Current exported functions are:

### Auth

- `onUserCreated`
  - trigger: Auth onCreate
  - behavior: sets default `customer` role and creates `users/{uid}`
- `onUserDeleted`
  - trigger: Auth onDelete
  - behavior: cleanup hook
- `setUserRole`
  - trigger: callable
  - auth: admin only

### Orders

- `onOrderCreated`
  - trigger: Firestore create
- `onOrderUpdated`
  - trigger: Firestore update
- `calculateFees`
  - trigger: callable
  - auth: authenticated user
- `cancelOrder`
  - trigger: callable
  - auth: authenticated user

### Notifications

- `sendChatNotification`
  - trigger: Firestore create
- `sendPromoNotification`
  - trigger: callable
  - auth: admin only

### Earnings

- `getEarningsSummary`
  - trigger: callable
  - auth: authenticated user, admin can query other partners
- `processPayout`
  - trigger: scheduled

### Analytics

- `getDashboardStats`
  - trigger: callable
  - auth: admin only
- `getRevenueReport`
  - trigger: callable
  - auth: admin only
- `dailyAggregation`
  - trigger: scheduled

### Reviews

- `onReviewCreated`
  - trigger: Firestore create
- `onReviewDeleted`
  - trigger: Firestore delete

### Promotions

- `validateCoupon`
  - trigger: callable
  - auth: authenticated user
- `expirePromotions`
  - trigger: scheduled

### Maintenance

- `cleanupOldLocations`
  - trigger: scheduled
- `cleanupOrphanData`
  - trigger: scheduled

## Shared Types

Current role values:

```ts
type UserRole = 'customer' | 'deliveryPartner' | 'restaurantOwner' | 'admin';
```

Current order status values used by functions:

```ts
type OrderStatus =
  | 'placed'
  | 'confirmed'
  | 'preparing'
  | 'readyForPickup'
  | 'pickedUp'
  | 'onTheWay'
  | 'delivered'
  | 'cancelled';
```

## Important Callable Contracts

### `setUserRole`

Source:

- `functions/src/auth/set_user_role.ts`

Current request shape:

```ts
interface SetUserRoleData {
  targetUid: string;
  role: string;
}
```

Current behavior:

- caller must be authenticated
- caller must have admin role
- target user must exist
- role must be one of the supported role constants
- function updates:
  - Firebase custom claims
  - Firestore `users/{uid}.role`

### `calculateFees`

Source:

- `functions/src/orders/calculate_fees.ts`

Current request shape:

```ts
interface CalculateFeesInput {
  subtotal: number;
  deliveryDistanceKm: number;
  couponCode?: string;
}
```

Current response shape:

```ts
interface FeeBreakdown {
  subtotal: number;
  deliveryFee: number;
  serviceFee: number;
  tax: number;
  discount: number;
  total: number;
}
```

### `validateCoupon`

Source:

- `functions/src/promotions/validate_coupon.ts`

Current request shape:

```ts
interface ValidateCouponInput {
  couponCode: string;
  subtotal: number;
}
```

Current response shape:

```ts
interface CouponValidation {
  valid: boolean;
  discountAmount: number;
  discountType?: string;
  discountValue?: number;
  maxDiscount?: number;
  message: string;
  promotionId?: string;
}
```

### `getDashboardStats`

Source:

- `functions/src/analytics/get_dashboard_stats.ts`

Current request shape:

```ts
interface DashboardStatsInput {
  startDate: string;
  endDate: string;
}
```

Current response fields:

- `totalOrders`
- `completedOrders`
- `cancelledOrders`
- `totalRevenue`
- `averageOrderValue`
- `activeUsers`
- `activeDeliveryPartners`
- `averageDeliveryTimeMinutes`

### `getEarningsSummary`

Source:

- `functions/src/earnings/get_earnings_summary.ts`

Current request shape:

```ts
interface GetEarningsInput {
  period: string;
  periodValue: string;
  deliveryPartnerId?: string;
}
```

Current response fields:

- `deliveryPartnerId`
- `period`
- `periodValue`
- `totalDeliveryFee`
- `totalTip`
- `totalBonus`
- `totalEarned`
- `deliveryCount`
- `averagePerDelivery`
- `isPaidOut`

### `sendPromoNotification`

Source:

- `functions/src/notifications/send_promo_notification.ts`

Current request fields:

- `title`
- `body`
- optional `targetRole`
- optional `targetUserIds`
- optional `data`

Current response fields:

- `success`
- `sentCount`

## Notes

- This document intentionally reflects the current exported surface rather than older aspirational APIs.
- Internal helpers such as `assignDeliveryPartner`, `send_order_notification`, and `on_delivery_completed` are not exported Cloud Functions and should not be documented as client-callable endpoints.
