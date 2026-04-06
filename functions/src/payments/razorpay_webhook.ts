/**
 * HTTP function – handles Razorpay webhook events.
 *
 * Verifies the webhook signature, then processes the event to keep
 * order payment status in sync with Razorpay.
 *
 * Handled events:
 *   - payment.captured  -> paymentStatus = completed
 *   - payment.failed    -> paymentStatus = failed
 *   - refund.created    -> paymentStatus = refunded
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import {defineSecret} from "firebase-functions/params";
import {
  Collections,
  PaymentStatuses,
  SubscriptionConstants,
  SubscriptionStatuses,
  SubCollections,
} from "../utils/constants";

const RAZORPAY_WEBHOOK_SECRET = defineSecret("RAZORPAY_WEBHOOK_SECRET");

const logger = functions.logger;

export const razorpayWebhook = functions
  .runWith({secrets: [RAZORPAY_WEBHOOK_SECRET]})
  .https.onRequest(async (req, res) => {
    // ── Only accept POST ────────────────────────────────────────────────
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    // ── Verify webhook signature ────────────────────────────────────────
    const webhookSecret = RAZORPAY_WEBHOOK_SECRET.value();
    const receivedSignature = req.headers["x-razorpay-signature"] as
      | string
      | undefined;

    if (!receivedSignature) {
      logger.warn("Razorpay webhook: missing signature header");
      res.status(400).send("Missing signature");
      return;
    }

    const expectedSignature = crypto
      .createHmac("sha256", webhookSecret)
      .update(JSON.stringify(req.body))
      .digest("hex");

    if (expectedSignature !== receivedSignature) {
      logger.warn("Razorpay webhook: invalid signature");
      res.status(400).send("Invalid signature");
      return;
    }

    // ── Process event ───────────────────────────────────────────────────
    const event = req.body.event as string | undefined;
    const payload = req.body.payload;

    if (!event || !payload) {
      logger.warn("Razorpay webhook: missing event or payload");
      res.status(400).send("Invalid payload");
      return;
    }

    logger.info(`Razorpay webhook received: ${event}`);

    const db = admin.firestore();

    try {
      switch (event) {
      case "payment.captured": {
        const payment = payload.payment?.entity;
        if (!payment) break;

        const razorpayOrderId = payment.order_id as string;
        await updateOrderPaymentStatus(
          db,
          razorpayOrderId,
          PaymentStatuses.COMPLETED,
          {razorpayPaymentId: payment.id}
        );
        break;
      }

      case "payment.failed": {
        const payment = payload.payment?.entity;
        if (!payment) break;

        const razorpayOrderId = payment.order_id as string;
        await updateOrderPaymentStatus(
          db,
          razorpayOrderId,
          PaymentStatuses.FAILED,
          {failureReason: payment.error_description || "Payment failed"}
        );
        break;
      }

      case "refund.created": {
        const refund = payload.refund?.entity;
        if (!refund) break;

        const razorpayOrderId = refund.order_id as string;
        await updateOrderPaymentStatus(
          db,
          razorpayOrderId,
          PaymentStatuses.REFUNDED,
          {
            refundId: refund.id,
            refundAmount: refund.amount,
          }
        );
        break;
      }

      // ── Subscription events ──────────────────────────────────────────
      case "subscription.authenticated": {
        const sub = payload.subscription?.entity;
        if (!sub) break;
        await updateRestaurantSubscription(db, sub.id, {
          subscriptionStatus: SubscriptionStatuses.AUTHENTICATED,
        });
        break;
      }

      case "subscription.activated": {
        const sub = payload.subscription?.entity;
        if (!sub) break;
        const currentEnd = sub.current_end
          ? admin.firestore.Timestamp.fromMillis(sub.current_end * 1000)
          : null;
        await updateRestaurantSubscription(db, sub.id, {
          subscriptionStatus: SubscriptionStatuses.ACTIVE,
          isSubscriptionValid: true,
          subscriptionCurrentEnd: currentEnd,
          subscriptionGraceDeadline: null,
        });
        await updateSubscriptionAudit(db, sub.id, {
          status: SubscriptionStatuses.ACTIVE,
          activatedAt: admin.firestore.FieldValue.serverTimestamp(),
          currentStart: sub.current_start
            ? admin.firestore.Timestamp.fromMillis(sub.current_start * 1000)
            : null,
          currentEnd,
        });
        break;
      }

      case "subscription.charged": {
        const sub = payload.subscription?.entity;
        const payment = payload.payment?.entity;
        if (!sub) break;
        const currentEnd = sub.current_end
          ? admin.firestore.Timestamp.fromMillis(sub.current_end * 1000)
          : null;
        await updateRestaurantSubscription(db, sub.id, {
          subscriptionStatus: SubscriptionStatuses.ACTIVE,
          isSubscriptionValid: true,
          subscriptionCurrentEnd: currentEnd,
          subscriptionGraceDeadline: null,
        });
        // Append to payment history
        if (payment) {
          await appendPaymentHistory(db, sub.id, {
            paymentId: payment.id,
            amount: payment.amount,
            status: "captured",
            date: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        await updateSubscriptionAudit(db, sub.id, {
          status: SubscriptionStatuses.ACTIVE,
          currentStart: sub.current_start
            ? admin.firestore.Timestamp.fromMillis(sub.current_start * 1000)
            : null,
          currentEnd,
        });
        break;
      }

      case "subscription.pending": {
        const sub = payload.subscription?.entity;
        if (!sub) break;
        // Compute grace deadline: current_end + 3 days
        const endMs = sub.current_end ? sub.current_end * 1000 : Date.now();
        const graceMs =
          endMs + SubscriptionConstants.GRACE_PERIOD_DAYS * 24 * 60 * 60 * 1000;
        await updateRestaurantSubscription(db, sub.id, {
          subscriptionStatus: SubscriptionStatuses.PENDING,
          isSubscriptionValid: true, // keep visible during grace
          subscriptionGraceDeadline:
            admin.firestore.Timestamp.fromMillis(graceMs),
        });
        await updateSubscriptionAudit(db, sub.id, {
          status: SubscriptionStatuses.PENDING,
        });
        break;
      }

      case "subscription.halted": {
        const sub = payload.subscription?.entity;
        if (!sub) break;
        await updateRestaurantSubscription(db, sub.id, {
          subscriptionStatus: SubscriptionStatuses.HALTED,
          isSubscriptionValid: false,
        });
        await updateSubscriptionAudit(db, sub.id, {
          status: SubscriptionStatuses.HALTED,
        });
        break;
      }

      case "subscription.cancelled":
      case "subscription.completed": {
        const sub = payload.subscription?.entity;
        if (!sub) break;
        const endMs = sub.current_end ? sub.current_end * 1000 : 0;
        const stillValid = endMs > Date.now();
        const graceDeadline = stillValid
          ? admin.firestore.Timestamp.fromMillis(
            endMs + SubscriptionConstants.GRACE_PERIOD_DAYS * 24 * 60 * 60 * 1000
          )
          : null;
        await updateRestaurantSubscription(db, sub.id, {
          subscriptionStatus: SubscriptionStatuses.CANCELLED,
          isSubscriptionValid: stillValid,
          subscriptionGraceDeadline: graceDeadline,
        });
        await updateSubscriptionAudit(db, sub.id, {
          status: SubscriptionStatuses.CANCELLED,
          cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        break;
      }

      default:
        logger.info(`Razorpay webhook: unhandled event ${event}`);
      }
    } catch (error) {
      logger.error(`Razorpay webhook: error processing ${event}`, error);
      // Return 200 anyway to prevent Razorpay from retrying indefinitely
    }

    res.status(200).send("OK");
  });

/**
 * Finds an order by its razorpayOrderId and updates its paymentStatus.
 */
async function updateOrderPaymentStatus(
  db: admin.firestore.Firestore,
  razorpayOrderId: string,
  status: string,
  extraFields: Record<string, unknown> = {}
): Promise<void> {
  const snapshot = await db
    .collection(Collections.ORDERS)
    .where("razorpayOrderId", "==", razorpayOrderId)
    .limit(1)
    .get();

  if (snapshot.empty) {
    logger.warn(
      `Razorpay webhook: no order found for razorpayOrderId ${razorpayOrderId}`
    );
    return;
  }

  const orderRef = snapshot.docs[0].ref;
  await orderRef.update({
    paymentStatus: status,
    ...extraFields,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  logger.info(
    `Order ${orderRef.id} paymentStatus updated to ${status}`,
    {razorpayOrderId}
  );
}

/**
 * Finds a restaurant by its subscriptionId and updates subscription fields.
 */
async function updateRestaurantSubscription(
  db: admin.firestore.Firestore,
  razorpaySubscriptionId: string,
  fields: Record<string, unknown>
): Promise<void> {
  const snapshot = await db
    .collection(Collections.RESTAURANTS)
    .where("subscriptionId", "==", razorpaySubscriptionId)
    .limit(1)
    .get();

  if (snapshot.empty) {
    logger.warn(
      `Razorpay webhook: no restaurant for subscriptionId ${razorpaySubscriptionId}`
    );
    return;
  }

  const ref = snapshot.docs[0].ref;
  await ref.update({
    ...fields,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  logger.info(
    `Restaurant ${ref.id} subscription updated`,
    {razorpaySubscriptionId, ...fields}
  );
}

/**
 * Updates the subscription audit sub-collection document.
 */
async function updateSubscriptionAudit(
  db: admin.firestore.Firestore,
  razorpaySubscriptionId: string,
  fields: Record<string, unknown>
): Promise<void> {
  const snapshot = await db
    .collection(Collections.RESTAURANTS)
    .where("subscriptionId", "==", razorpaySubscriptionId)
    .limit(1)
    .get();

  if (snapshot.empty) return;

  const restaurantRef = snapshot.docs[0].ref;
  const auditRef = restaurantRef
    .collection(SubCollections.SUBSCRIPTIONS)
    .doc(razorpaySubscriptionId);

  const auditDoc = await auditRef.get();
  if (auditDoc.exists) {
    await auditRef.update(fields);
  }
}

/**
 * Appends a payment entry to the subscription audit's paymentHistory array.
 */
async function appendPaymentHistory(
  db: admin.firestore.Firestore,
  razorpaySubscriptionId: string,
  entry: Record<string, unknown>
): Promise<void> {
  const snapshot = await db
    .collection(Collections.RESTAURANTS)
    .where("subscriptionId", "==", razorpaySubscriptionId)
    .limit(1)
    .get();

  if (snapshot.empty) return;

  const restaurantRef = snapshot.docs[0].ref;
  const auditRef = restaurantRef
    .collection(SubCollections.SUBSCRIPTIONS)
    .doc(razorpaySubscriptionId);

  const auditDoc = await auditRef.get();
  if (auditDoc.exists) {
    await auditRef.update({
      paymentHistory: admin.firestore.FieldValue.arrayUnion(entry),
    });
  }
}
