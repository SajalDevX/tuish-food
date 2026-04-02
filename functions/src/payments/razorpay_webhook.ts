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
import {Collections, PaymentStatuses} from "../utils/constants";

const logger = functions.logger;

export const razorpayWebhook = functions.https.onRequest(
  async (req, res) => {
    // ── Only accept POST ────────────────────────────────────────────────
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    // ── Verify webhook signature ────────────────────────────────────────
    const webhookSecret = functions.config().razorpay.webhook_secret;
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

      default:
        logger.info(`Razorpay webhook: unhandled event ${event}`);
      }
    } catch (error) {
      logger.error(`Razorpay webhook: error processing ${event}`, error);
      // Return 200 anyway to prevent Razorpay from retrying indefinitely
    }

    res.status(200).send("OK");
  }
);

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
