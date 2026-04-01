/**
 * Cloud Functions entry point for Tuish Food.
 *
 * Initializes firebase-admin and re-exports every function from
 * the sub-modules so that `firebase deploy --only functions`
 * discovers them all.
 */

import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK (must be called before any other admin usage)
admin.initializeApp();

// ── Auth triggers ───────────────────────────────────────────────────────────
export {onUserCreated} from "./auth/on_user_created";
export {setUserRole} from "./auth/set_user_role";
export {onUserDeleted} from "./auth/on_user_deleted";

// ── Order triggers & callables ──────────────────────────────────────────────
export {onOrderCreated} from "./orders/on_order_created";
export {onOrderUpdated} from "./orders/on_order_updated";
export {calculateFees} from "./orders/calculate_fees";
export {cancelOrder} from "./orders/cancel_order";
// Note: assignDeliveryPartner is an internal helper, not a Cloud Function

// ── Notifications ───────────────────────────────────────────────────────────
export {sendChatNotification} from "./notifications/send_chat_notification";
export {sendPromoNotification} from "./notifications/send_promo_notification";
// Note: fcm_helpers and send_order_notification are internal helpers

// ── Earnings ────────────────────────────────────────────────────────────────
export {getEarningsSummary} from "./earnings/get_earnings_summary";
export {processPayout} from "./earnings/process_payout";
// Note: onDeliveryCompleted is an internal helper called by onOrderUpdated

// ── Analytics ───────────────────────────────────────────────────────────────
export {getDashboardStats} from "./analytics/get_dashboard_stats";
export {getRevenueReport} from "./analytics/get_revenue_report";
export {dailyAggregation} from "./analytics/daily_aggregation";

// ── Reviews ─────────────────────────────────────────────────────────────────
export {onReviewCreated} from "./reviews/on_review_created";
export {onReviewDeleted} from "./reviews/on_review_deleted";

// ── Promotions ──────────────────────────────────────────────────────────────
export {validateCoupon} from "./promotions/validate_coupon";
export {expirePromotions} from "./promotions/expire_promotions";

// ── Maintenance ─────────────────────────────────────────────────────────────
export {cleanupOldLocations} from "./maintenance/cleanup_old_locations";
export {cleanupOrphanData} from "./maintenance/cleanup_orphan_data";
