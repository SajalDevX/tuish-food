/**
 * Callable function – processes a refund via Razorpay.
 *
 * Admin-only. Initiates a full or partial refund for a given payment.
 *
 * Input:  { paymentId: string, amount?: number }
 * Output: { success: true, refundId: string }
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {defineSecret} from "firebase-functions/params";
import {Collections, PaymentStatuses, UserRoles} from "../utils/constants";

// eslint-disable-next-line @typescript-eslint/no-var-requires
const Razorpay = require("razorpay");

const RAZORPAY_KEY_ID = defineSecret("RAZORPAY_KEY_ID");
const RAZORPAY_KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");

const logger = functions.logger;

interface ProcessRazorpayRefundInput {
  paymentId: string;
  amount?: number;
}

export const processRazorpayRefund = functions
  .runWith({secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET]})
  .https.onCall(async (data: ProcessRazorpayRefundInput, context) => {
    // ── Auth check (admin only) ─────────────────────────────────────────
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in."
      );
    }

    const callerRole = context.auth.token.role as string | undefined;
    if (callerRole !== UserRoles.ADMIN) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can process refunds."
      );
    }

    // ── Validate input ──────────────────────────────────────────────────
    const {paymentId, amount} = data;

    if (!paymentId || typeof paymentId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "paymentId is required and must be a string."
      );
    }

    if (amount !== undefined && (typeof amount !== "number" || amount <= 0)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "amount must be a positive number if provided."
      );
    }

    // ── Initialize Razorpay ─────────────────────────────────────────────
    const razorpay = new Razorpay({
      key_id: RAZORPAY_KEY_ID.value(),
      key_secret: RAZORPAY_KEY_SECRET.value(),
    });

    // ── Process refund ──────────────────────────────────────────────────
    try {
      const refundOptions: Record<string, unknown> = {};
      if (amount) {
        refundOptions.amount = Math.round(amount * 100); // Convert INR to paise
      }

      const refund = await razorpay.payments.refund(paymentId, refundOptions);

      logger.info(`Refund processed: ${refund.id}`, {
        paymentId,
        amount: refund.amount,
        uid: context.auth.uid,
      });

      // ── Update order paymentStatus ──────────────────────────────────
      const db = admin.firestore();
      const snapshot = await db
        .collection(Collections.ORDERS)
        .where("razorpayPaymentId", "==", paymentId)
        .limit(1)
        .get();

      if (!snapshot.empty) {
        const orderRef = snapshot.docs[0].ref;
        await orderRef.update({
          paymentStatus: PaymentStatuses.REFUNDED,
          refundId: refund.id,
          refundAmount: refund.amount,
          refundedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        logger.info(`Order ${orderRef.id} marked as refunded`);
      } else {
        logger.warn(
          `No order found for paymentId ${paymentId} to update status`
        );
      }

      return {
        success: true,
        refundId: refund.id,
      };
    } catch (error) {
      logger.error("Failed to process Razorpay refund", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to process refund. Please try again."
      );
    }
  });
