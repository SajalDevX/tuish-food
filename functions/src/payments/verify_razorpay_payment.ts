/**
 * Callable function – verifies a Razorpay payment signature and creates
 * the order in Firestore upon successful verification.
 *
 * Input:  { razorpayOrderId, razorpayPaymentId, razorpaySignature, orderData }
 * Output: { success: true, orderId: string }
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import {
  Collections,
  PaymentStatuses,
  UserRoles,
} from "../utils/constants";

const logger = functions.logger;

interface VerifyRazorpayPaymentInput {
  razorpayOrderId: string;
  razorpayPaymentId: string;
  razorpaySignature: string;
  orderData: Record<string, unknown>;
}

export const verifyRazorpayPayment = functions.https.onCall(
  async (data: VerifyRazorpayPaymentInput, context) => {
    // ── Auth check (customer role) ──────────────────────────────────────
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in."
      );
    }

    const callerRole = context.auth.token.role as string | undefined;
    if (callerRole !== UserRoles.CUSTOMER) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only customers can verify payments."
      );
    }

    // ── Validate input ──────────────────────────────────────────────────
    const {razorpayOrderId, razorpayPaymentId, razorpaySignature, orderData} =
      data;

    if (
      !razorpayOrderId ||
      typeof razorpayOrderId !== "string" ||
      !razorpayPaymentId ||
      typeof razorpayPaymentId !== "string" ||
      !razorpaySignature ||
      typeof razorpaySignature !== "string"
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "razorpayOrderId, razorpayPaymentId, and razorpaySignature are required."
      );
    }

    if (!orderData || typeof orderData !== "object") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "orderData is required and must be an object."
      );
    }

    // ── Verify signature ────────────────────────────────────────────────
    const keySecret = functions.config().razorpay.key_secret;
    const expectedSignature = crypto
      .createHmac("sha256", keySecret)
      .update(razorpayOrderId + "|" + razorpayPaymentId)
      .digest("hex");

    if (expectedSignature !== razorpaySignature) {
      logger.warn("Razorpay signature verification failed", {
        razorpayOrderId,
        razorpayPaymentId,
        uid: context.auth.uid,
      });
      throw new functions.https.HttpsError(
        "permission-denied",
        "Payment verification failed. Invalid signature."
      );
    }

    // ── Create order in Firestore ───────────────────────────────────────
    try {
      const db = admin.firestore();
      const orderRef = db.collection(Collections.ORDERS).doc();

      await orderRef.set({
        ...orderData,
        paymentStatus: PaymentStatuses.COMPLETED,
        razorpayOrderId,
        razorpayPaymentId,
        customerId: context.auth.uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info(`Order created after payment verification: ${orderRef.id}`, {
        razorpayOrderId,
        razorpayPaymentId,
        uid: context.auth.uid,
      });

      return {
        success: true,
        orderId: orderRef.id,
      };
    } catch (error) {
      logger.error("Failed to create order after payment verification", error);
      throw new functions.https.HttpsError(
        "internal",
        "Payment verified but failed to create order. Please contact support."
      );
    }
  }
);
