/**
 * Firestore trigger – fires when a new order document is created.
 *
 * Responsibilities:
 *  1. Validate the order data.
 *  2. Create a notification for the restaurant.
 *  3. Attempt to assign a delivery partner.
 *  4. Set estimatedDeliveryTime on the order.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  Collections,
  Delivery,
  OrderStatuses,
  NotificationTypes,
} from "../utils/constants";
import {validateOrderData} from "../utils/validation";
import {assignDeliveryPartner} from "./assign_delivery_partner";
import {createNotificationDoc} from "../notifications/fcm_helpers";

const logger = functions.logger;

export const onOrderCreated = functions.firestore
  .document(`${Collections.ORDERS}/{orderId}`)
  .onCreate(async (snapshot, context) => {
    const orderId = context.params.orderId;
    const orderData = snapshot.data();

    logger.info(`New order created: ${orderId}`, {orderId});

    // ── 1. Validate ───────────────────────────────────────────────────────
    const validation = validateOrderData(orderData);
    if (!validation.valid) {
      logger.error(
        `Order ${orderId} validation failed: ${validation.errors.join("; ")}`
      );
      // Mark order as invalid but do not delete – let admins inspect it
      await snapshot.ref.update({
        _validationErrors: validation.errors,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    const restaurantId = orderData.restaurantId as string;
    const orderNumber = (orderData.orderNumber as string) || orderId;
    const restaurantName = (orderData.restaurantName as string) || "Restaurant";

    // ── 2. Create notification for restaurant owner ─────────────────────
    // Restaurants may be operated by a user whose uid matches the restaurant
    // doc id, or we store an ownerId field.
    const restaurantDoc = await admin
      .firestore()
      .collection(Collections.RESTAURANTS)
      .doc(restaurantId)
      .get();

    const ownerId = restaurantDoc.data()?.ownerId as string | undefined;
    if (ownerId) {
      await createNotificationDoc(
        ownerId,
        "New Order Received",
        `You have a new order #${orderNumber}.`,
        NotificationTypes.ORDER_UPDATE,
        {orderId, orderNumber}
      );
    }

    // ── 3. Assign delivery partner ──────────────────────────────────────
    const assignment = await assignDeliveryPartner(orderId, restaurantId);

    // ── 4. Set estimatedDeliveryTime ────────────────────────────────────
    const prepTime =
      (restaurantDoc.data()?.preparationTimeMinutes as number) || 30;
    const estimatedMinutes =
      prepTime +
      (assignment.assigned
        ? Delivery.DEFAULT_ESTIMATED_DELIVERY_MINUTES - prepTime
        : Delivery.DEFAULT_ESTIMATED_DELIVERY_MINUTES);
    const estimatedDeliveryTime = new Date(
      Date.now() + estimatedMinutes * 60 * 1000
    );

    // ── 5. Update order with delivery info ──────────────────────────────
    const updatePayload: Record<string, unknown> = {
      estimatedDeliveryTime: admin.firestore.Timestamp.fromDate(
        estimatedDeliveryTime
      ),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Ensure statusHistory has the 'placed' entry
    const existingHistory = (orderData.statusHistory as unknown[]) || [];
    if (existingHistory.length === 0) {
      updatePayload.statusHistory = [
        {
          status: OrderStatuses.PLACED,
          timestamp: admin.firestore.Timestamp.now(),
          note: "Order placed",
        },
      ];
    }

    await snapshot.ref.update(updatePayload);

    logger.info(
      `Order ${orderId} processed: partner=${
        assignment.deliveryPartnerId ?? "none"
      }, ` +
        `est=${estimatedMinutes}min, restaurant=${restaurantName}`
    );
  });
