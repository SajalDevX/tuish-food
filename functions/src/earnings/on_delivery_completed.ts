/**
 * Exported helper – called when an order's status transitions to 'delivered'.
 * Creates an earnings document for the delivery partner.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections, NotificationTypes} from "../utils/constants";
import {
  createNotificationDoc,
} from "../notifications/fcm_helpers";

const logger = functions.logger;

/**
 * Return ISO‑week string like "2026-W13".
 */
function isoWeek(date: Date): string {
  const d = new Date(
    Date.UTC(date.getFullYear(), date.getMonth(), date.getDate())
  );
  const dayNum = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - dayNum);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  const weekNo = Math.ceil(
    ((d.getTime() - yearStart.getTime()) / 86400000 + 1) / 7
  );
  return `${d.getUTCFullYear()}-W${String(weekNo).padStart(2, "0")}`;
}

/**
 * Return month string like "2026-03".
 */
function isoMonth(date: Date): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
}

/**
 * Called by on_order_updated when status becomes 'delivered'.
 */
export async function onDeliveryCompleted(
  orderId: string,
  orderData: FirebaseFirestore.DocumentData
): Promise<void> {
  const deliveryPartnerId = orderData.deliveryPartnerId as string | undefined;
  if (!deliveryPartnerId) {
    logger.warn(`No delivery partner on order ${orderId} – skipping earnings`);
    return;
  }

  const db = admin.firestore();
  const now = new Date();

  const deliveryFee = (orderData.deliveryFee as number) || 0;
  const tip = (orderData.tip as number) || 0;
  const orderNumber = (orderData.orderNumber as string) || orderId;

  // Bonus: 10 bonus for orders delivered within estimated time
  let bonus = 0;
  const estimatedTime = orderData.estimatedDeliveryTime?.toDate?.() as
    | Date
    | undefined;
  if (estimatedTime && now <= estimatedTime) {
    bonus = 10;
  }

  const totalEarned = deliveryFee + tip + bonus;

  const earningsData: Record<string, unknown> = {
    deliveryPartnerId,
    orderId,
    orderNumber,
    deliveryFee,
    tip,
    bonus,
    totalEarned,
    date: admin.firestore.Timestamp.fromDate(now),
    week: isoWeek(now),
    month: isoMonth(now),
    isPaidOut: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  try {
    const docRef = await db
      .collection(Collections.EARNINGS)
      .add(earningsData);

    logger.info(
      `Earnings doc ${docRef.id} created for partner ${deliveryPartnerId} ` +
        `on order ${orderId}: total=${totalEarned}`
    );

    // Notify the delivery partner
    await createNotificationDoc(
      deliveryPartnerId,
      "Delivery Completed",
      `You earned ₹${totalEarned.toFixed(0)} for order #${orderNumber}${
        bonus > 0 ? ` (includes ₹${bonus} bonus!)` : ""
      }.`,
      NotificationTypes.EARNINGS,
      {orderId, amount: totalEarned.toString()}
    );
  } catch (error) {
    logger.error(
      `Failed to create earnings for order ${orderId}`,
      error
    );
    throw error;
  }
}
