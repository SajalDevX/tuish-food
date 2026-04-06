/**
 * Callable function – cancels a restaurant's Razorpay subscription at cycle end.
 *
 * Input:  { restaurantId: string }
 * Output: { success: true }
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {defineSecret} from "firebase-functions/params";
import {
  Collections,
  SubCollections,
  SubscriptionStatuses,
} from "../utils/constants";

// eslint-disable-next-line @typescript-eslint/no-var-requires
const Razorpay = require("razorpay");

const RAZORPAY_KEY_ID = defineSecret("RAZORPAY_KEY_ID");
const RAZORPAY_KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");

const logger = functions.logger;

interface CancelSubscriptionInput {
  restaurantId: string;
}

export const cancelSubscription = functions
  .runWith({secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET]})
  .https.onCall(async (data: CancelSubscriptionInput, context) => {
    // ── Auth check ─────────────────────────────────────────────────────
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in."
      );
    }

    const {restaurantId} = data;

    if (!restaurantId || typeof restaurantId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "restaurantId is required and must be a string."
      );
    }

    // ── Verify ownership ───────────────────────────────────────────────
    const db = admin.firestore();
    const restaurantRef = db.collection(Collections.RESTAURANTS).doc(restaurantId);
    const restaurantDoc = await restaurantRef.get();

    if (!restaurantDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Restaurant not found."
      );
    }

    const restaurantData = restaurantDoc.data()!;
    if (restaurantData.ownerUid !== context.auth.uid) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "You do not own this restaurant."
      );
    }

    const subscriptionId = restaurantData.subscriptionId as string | undefined;
    if (!subscriptionId) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "No active subscription found."
      );
    }

    // ── Cancel on Razorpay (at cycle end) ──────────────────────────────
    const razorpay = new Razorpay({
      key_id: RAZORPAY_KEY_ID.value(),
      key_secret: RAZORPAY_KEY_SECRET.value(),
    });

    try {
      await razorpay.subscriptions.cancel(subscriptionId, {
        cancel_at_cycle_end: true,
      });

      logger.info(`Subscription cancelled: ${subscriptionId}`, {
        restaurantId,
        uid: context.auth.uid,
      });

      // ── Update restaurant doc ──────────────────────────────────────
      await restaurantRef.update({
        subscriptionStatus: SubscriptionStatuses.CANCELLED,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // ── Update audit record ────────────────────────────────────────
      const auditRef = restaurantRef
        .collection(SubCollections.SUBSCRIPTIONS)
        .doc(subscriptionId);
      const auditDoc = await auditRef.get();
      if (auditDoc.exists) {
        await auditRef.update({
          status: SubscriptionStatuses.CANCELLED,
          cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      return {success: true};
    } catch (error) {
      logger.error("Failed to cancel Razorpay subscription", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to cancel subscription. Please try again."
      );
    }
  });
