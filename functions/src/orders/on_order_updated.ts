/**
 * Firestore trigger – fires when an order document is updated.
 *
 * Detects status transitions and:
 *  - Sends FCM push to the customer for every status change.
 *  - On 'delivered' status, triggers earnings calculation.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  Collections,
  OrderStatuses,
  OrderStatus,
} from "../utils/constants";
import {sendOrderNotification} from "../notifications/send_order_notification";
import {onDeliveryCompleted} from "../earnings/on_delivery_completed";

const logger = functions.logger;

export const onOrderUpdated = functions.firestore
  .document(`${Collections.ORDERS}/{orderId}`)
  .onUpdate(async (change, context) => {
    const orderId = context.params.orderId;
    const before = change.before.data();
    const after = change.after.data();

    const oldStatus = before.status as OrderStatus | undefined;
    const newStatus = after.status as OrderStatus | undefined;

    // Only react to actual status changes
    if (!newStatus || oldStatus === newStatus) {
      return;
    }

    logger.info(
      `Order ${orderId} status changed: ${oldStatus ?? "null"} -> ${newStatus}`
    );

    const customerId = after.customerId as string;
    const orderNumber = (after.orderNumber as string) || orderId;
    const restaurantId = after.restaurantId as string;
    const deliveryPartnerId = after.deliveryPartnerId as string | undefined;

    // ── 1. Append to statusHistory ──────────────────────────────────────
    const historyEntry = {
      status: newStatus,
      timestamp: admin.firestore.Timestamp.now(),
    };

    await change.after.ref.update({
      statusHistory: admin.firestore.FieldValue.arrayUnion(historyEntry),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // ── 2. Send push notification to customer ───────────────────────────
    await sendOrderNotification({
      orderId,
      orderNumber,
      customerId,
      deliveryPartnerId,
      restaurantId,
      status: newStatus,
    });

    // ── 3. Handle delivered status ──────────────────────────────────────
    if (newStatus === OrderStatuses.DELIVERED) {
      // Set actual delivery time
      await change.after.ref.update({
        actualDeliveryTime: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Trigger earnings calculation
      if (deliveryPartnerId) {
        await onDeliveryCompleted(orderId, after);
      }

      // Free up the delivery partner
      if (deliveryPartnerId) {
        try {
          await admin
            .firestore()
            .collection(Collections.DELIVERY_LOCATIONS)
            .doc(deliveryPartnerId)
            .update({
              hasActiveOrder: false,
              activeOrderId: null,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        } catch (err) {
          logger.warn(
            `Could not free delivery partner ${deliveryPartnerId}`,
            err
          );
        }
      }

      // Increment restaurant's totalOrders
      try {
        await admin
          .firestore()
          .collection(Collections.RESTAURANTS)
          .doc(restaurantId)
          .update({
            totalOrders: admin.firestore.FieldValue.increment(1),
          });
      } catch (err) {
        logger.warn(
          `Could not increment totalOrders for restaurant ${restaurantId}`,
          err
        );
      }
    }

    // ── 4. Handle cancelled status – free delivery partner ──────────────
    if (newStatus === OrderStatuses.CANCELLED && deliveryPartnerId) {
      try {
        await admin
          .firestore()
          .collection(Collections.DELIVERY_LOCATIONS)
          .doc(deliveryPartnerId)
          .update({
            hasActiveOrder: false,
            activeOrderId: null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
      } catch (err) {
        logger.warn(
          `Could not free delivery partner ${deliveryPartnerId} after cancel`,
          err
        );
      }
    }
  });
