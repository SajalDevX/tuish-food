/**
 * Shared constants for Tuish Food Cloud Functions.
 */

// ── Firestore collection names ──────────────────────────────────────────────
export const Collections = {
  USERS: "users",
  RESTAURANTS: "restaurants",
  ORDERS: "orders",
  REVIEWS: "reviews",
  DELIVERY_LOCATIONS: "delivery_locations",
  CHATS: "chats",
  EARNINGS: "earnings",
  PROMOTIONS: "promotions",
  NOTIFICATIONS: "notifications",
  APP_CONFIG: "app_config",
} as const;

// ── Firestore sub‑collection names ──────────────────────────────────────────
export const SubCollections = {
  ADDRESSES: "addresses",
  MENU_CATEGORIES: "menuCategories",
  MENU_ITEMS: "menuItems",
  MESSAGES: "messages",
} as const;

// ── App config document IDs ─────────────────────────────────────────────────
export const AppConfigDocs = {
  SETTINGS: "settings",
} as const;

// ── Fee & pricing constants ─────────────────────────────────────────────────
export const Fees = {
  /** 5 % of subtotal */
  SERVICE_FEE_PERCENTAGE: 0.05,
  /** Default flat delivery fee in INR */
  DEFAULT_DELIVERY_FEE: 40,
  /** 5 % tax */
  TAX_PERCENTAGE: 0.05,
  /** Per‑km surcharge above base delivery distance */
  PER_KM_SURCHARGE: 5,
  /** Base distance (km) included in the default delivery fee */
  BASE_DELIVERY_DISTANCE_KM: 3,
} as const;

// ── Delivery constants ──────────────────────────────────────────────────────
export const Delivery = {
  /** Maximum radius (km) to search for delivery partners */
  MAX_DELIVERY_RADIUS_KM: 10,
  /** Default estimated delivery time in minutes */
  DEFAULT_ESTIMATED_DELIVERY_MINUTES: 45,
} as const;

// ── Order statuses (mirrors Flutter OrderStatus enum) ───────────────────────
export const OrderStatuses = {
  PLACED: "placed",
  CONFIRMED: "confirmed",
  PREPARING: "preparing",
  READY_FOR_PICKUP: "readyForPickup",
  PICKED_UP: "pickedUp",
  ON_THE_WAY: "onTheWay",
  DELIVERED: "delivered",
  CANCELLED: "cancelled",
} as const;

export type OrderStatus = (typeof OrderStatuses)[keyof typeof OrderStatuses];

// ── User roles ──────────────────────────────────────────────────────────────
export const UserRoles = {
  CUSTOMER: "customer",
  DELIVERY_PARTNER: "deliveryPartner",
  RESTAURANT_OWNER: "restaurantOwner",
  ADMIN: "admin",
} as const;

export type UserRole = (typeof UserRoles)[keyof typeof UserRoles];

// ── Payment statuses ────────────────────────────────────────────────────────
export const PaymentStatuses = {
  PENDING: "pending",
  COMPLETED: "completed",
  FAILED: "failed",
  REFUNDED: "refunded",
} as const;

export type PaymentStatus =
  (typeof PaymentStatuses)[keyof typeof PaymentStatuses];

// ── Notification types ──────────────────────────────────────────────────────
export const NotificationTypes = {
  ORDER_UPDATE: "order_update",
  PROMOTION: "promotion",
  CHAT: "chat",
  SYSTEM: "system",
  EARNINGS: "earnings",
} as const;

export type NotificationType =
  (typeof NotificationTypes)[keyof typeof NotificationTypes];
