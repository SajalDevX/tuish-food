/**
 * Callable function – cancels an order.
 *
 * Verifies the caller is the order's customer or an admin, then
 * updates the status to 'cancelled', appends to statusHistory,
 * and initiates refund logic if payment was completed.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  Collections,
  OrderStatuses,
  PaymentStatuses,
  UserRoles,
} from "../utils/constants";

const logger = functions.logger;

interface CancelOrderInput {
  orderId: string;
  reason?: string;
}

export const cancelOrder = functions.https.onCall(
  async (data: CancelOrderInput, context) => {
    // ── Auth check ──────────────────────────────────────────────────────
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in."
      );
    }

    const {orderId, reason} = data;
    if (!orderId || typeof orderId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "orderId is required."
      );
    }

    const db = admin.firestore();
    const orderRef = db.collection(Collections.ORDERS).doc(orderId);
    const orderDoc = await orderRef.get();

    if (!orderDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Order not found.");
    }

    const orderData = orderDoc.data()!;
    const callerUid = context.auth.uid;
    const callerRole = context.auth.token.role as string | undefined;
    const customerId = orderData.customerId as string;

    // Only the customer who placed the order or an admin can cancel
    if (callerUid !== customerId && callerRole !== UserRoles.ADMIN) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "You do not have permission to cancel this order."
      );
    }

    // Check current status – cannot cancel already terminal orders
    const currentStatus = orderData.status as string;
    if (
      currentStatus === OrderStatuses.DELIVERED ||
      currentStatus === OrderStatuses.CANCELLED
    ) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `Order is already ${currentStatus} and cannot be cancelled.`
      );
    }

    // Cannot cancel once the order is picked up (unless admin)
    const nonCancellable = [
      OrderStatuses.PICKED_UP,
      OrderStatuses.ON_THE_WAY,
    ] as string[];
    if (
      nonCancellable.includes(currentStatus) &&
      callerRole !== UserRoles.ADMIN
    ) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Order has already been picked up and cannot be cancelled by the customer."
      );
    }

    // ── Update order ────────────────────────────────────────────────────
    const now = admin.firestore.Timestamp.now();
    const historyEntry = {
      status: OrderStatuses.CANCELLED,
      timestamp: now,
      note: reason || "Cancelled by user",
    };

    const updatePayload: Record<string, unknown> = {
      status: OrderStatuses.CANCELLED,
      statusHistory: admin.firestore.FieldValue.arrayUnion(historyEntry),
      cancellationReason: reason || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // If payment was completed, flag for refund
    const paymentStatus = orderData.paymentStatus as string;
    if (paymentStatus === PaymentStatuses.COMPLETED) {
      updatePayload.paymentStatus = PaymentStatuses.REFUNDED;
      updatePayload.refundInitiatedAt =
        admin.firestore.FieldValue.serverTimestamp();
      logger.info(`Refund initiated for order ${orderId}`);
    }

    await orderRef.update(updatePayload);

    logger.info(`Order ${orderId} cancelled by ${callerUid}`, {
      reason,
      previousStatus: currentStatus,
    });

    return {
      success: true,
      orderId,
      refundInitiated: paymentStatus === PaymentStatuses.COMPLETED,
    };
  }
);
