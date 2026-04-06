/**
 * Callable function – creates a Razorpay order for payment.
 *
 * Input:  { amount: number, receipt: string, notes?: Record<string, string> }
 * Output: { razorpayOrderId: string, amount: number }
 */

import * as functions from "firebase-functions";
import {defineSecret} from "firebase-functions/params";
// eslint-disable-next-line @typescript-eslint/no-var-requires
const Razorpay = require("razorpay");

const RAZORPAY_KEY_ID = defineSecret("RAZORPAY_KEY_ID");
const RAZORPAY_KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");

const logger = functions.logger;

interface CreateRazorpayOrderInput {
  amount: number;
  receipt: string;
  notes?: Record<string, string>;
}

export const createRazorpayOrder = functions
  .runWith({secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET]})
  .https.onCall(async (data: CreateRazorpayOrderInput, context) => {
    // ── Auth check ──────────────────────────────────────────────────────
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in."
      );
    }

    // ── Validate input ──────────────────────────────────────────────────
    const {amount, receipt, notes} = data;

    if (typeof amount !== "number" || amount <= 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "amount must be a positive number (in INR)."
      );
    }

    if (!receipt || typeof receipt !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "receipt is required and must be a string."
      );
    }

    // ── Initialize Razorpay ─────────────────────────────────────────────
    const razorpay = new Razorpay({
      key_id: RAZORPAY_KEY_ID.value(),
      key_secret: RAZORPAY_KEY_SECRET.value(),
    });

    // ── Create order ────────────────────────────────────────────────────
    const amountInPaise = Math.round(amount * 100);

    try {
      const order = await razorpay.orders.create({
        amount: amountInPaise,
        currency: "INR",
        receipt,
        notes: notes || {},
      });

      logger.info(`Razorpay order created: ${order.id}`, {
        amount: order.amount,
        receipt,
        uid: context.auth.uid,
      });

      return {
        razorpayOrderId: order.id,
        amount: order.amount,
      };
    } catch (error) {
      logger.error("Failed to create Razorpay order", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to create Razorpay order. Please try again."
      );
    }
  });
