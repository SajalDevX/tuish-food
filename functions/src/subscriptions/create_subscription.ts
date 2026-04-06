/**
 * Callable function – creates a Razorpay subscription for a restaurant owner.
 *
 * Input:  { restaurantId: string }
 * Output: { subscriptionId: string }
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {defineSecret} from "firebase-functions/params";
import {
  Collections,
  SubCollections,
  SubscriptionConstants,
  SubscriptionStatuses,
} from "../utils/constants";

// eslint-disable-next-line @typescript-eslint/no-var-requires
const Razorpay = require("razorpay");

const RAZORPAY_KEY_ID = defineSecret("RAZORPAY_KEY_ID");
const RAZORPAY_KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");

const logger = functions.logger;

interface CreateSubscriptionInput {
  restaurantId: string;
}

export const createSubscription = functions
  .runWith({secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET]})
  .https.onCall(async (data: CreateSubscriptionInput, context) => {
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

    // ── Check if already has an active subscription ────────────────────
    if (
      restaurantData.subscriptionStatus === SubscriptionStatuses.ACTIVE ||
      restaurantData.subscriptionStatus === SubscriptionStatuses.AUTHENTICATED
    ) {
      throw new functions.https.HttpsError(
        "already-exists",
        "Restaurant already has an active subscription."
      );
    }

    // ── Create Razorpay subscription ───────────────────────────────────
    const keyId = RAZORPAY_KEY_ID.value();
    const keySecret = RAZORPAY_KEY_SECRET.value();

    logger.info("Razorpay init", {
      keyIdLength: keyId?.length ?? 0,
      keySecretLength: keySecret?.length ?? 0,
      keyIdPrefix: keyId?.substring(0, 8) ?? "empty",
    });

    const razorpay = new Razorpay({
      key_id: keyId,
      key_secret: keySecret,
    });

    try {
      const subscription = await razorpay.subscriptions.create({
        plan_id: SubscriptionConstants.PLAN_ID,
        total_count: 120, // up to 10 years
        notes: {
          restaurantId,
          ownerUid: context.auth.uid,
        },
      });

      logger.info(`Subscription created: ${subscription.id}`, {
        restaurantId,
        uid: context.auth.uid,
      });

      // ── Update restaurant doc ──────────────────────────────────────
      await restaurantRef.update({
        subscriptionStatus: SubscriptionStatuses.CREATED,
        subscriptionId: subscription.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // ── Create audit record ────────────────────────────────────────
      await restaurantRef
        .collection(SubCollections.SUBSCRIPTIONS)
        .doc(subscription.id)
        .set({
          razorpaySubscriptionId: subscription.id,
          razorpayPlanId: SubscriptionConstants.PLAN_ID,
          status: SubscriptionStatuses.CREATED,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          activatedAt: null,
          cancelledAt: null,
          currentStart: null,
          currentEnd: null,
          paymentHistory: [],
        });

      return {
        subscriptionId: subscription.id,
      };
    } catch (error) {
      logger.error("Failed to create Razorpay subscription", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to create subscription. Please try again."
      );
    }
  });
