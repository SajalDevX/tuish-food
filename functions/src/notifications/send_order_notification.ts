/**
 * Helper called by order triggers to send status‑specific push
 * notifications and create in‑app notification documents.
 */

import * as functions from "firebase-functions";
import {OrderStatus, NotificationTypes} from "../utils/constants";
import {sendToUser, createNotificationDoc} from "./fcm_helpers";

const logger = functions.logger;

interface OrderNotificationPayload {
  orderId: string;
  orderNumber: string;
  customerId: string;
  deliveryPartnerId?: string;
  restaurantId: string;
  status: OrderStatus;
}

/**
 * Map order status to user‑friendly notification title/body.
 */
function statusToNotification(
  status: OrderStatus,
  orderNumber: string
): {title: string; body: string} {
  switch (status) {
  case "placed":
    return {
      title: "Order Placed",
      body: `Your order #${orderNumber} has been placed successfully.`,
    };
  case "confirmed":
    return {
      title: "Order Confirmed",
      body: `Restaurant has confirmed your order #${orderNumber}.`,
    };
  case "preparing":
    return {
      title: "Preparing Your Food",
      body: `Your order #${orderNumber} is being prepared.`,
    };
  case "readyForPickup":
    return {
      title: "Ready for Pickup",
      body: `Your order #${orderNumber} is ready and waiting for a rider.`,
    };
  case "pickedUp":
    return {
      title: "Order Picked Up",
      body: `A delivery partner has picked up your order #${orderNumber}.`,
    };
  case "onTheWay":
    return {
      title: "On the Way!",
      body: `Your order #${orderNumber} is on its way to you.`,
    };
  case "delivered":
    return {
      title: "Order Delivered",
      body: `Your order #${orderNumber} has been delivered. Enjoy!`,
    };
  case "cancelled":
    return {
      title: "Order Cancelled",
      body: `Your order #${orderNumber} has been cancelled.`,
    };
  default:
    return {
      title: "Order Update",
      body: `Your order #${orderNumber} status has been updated.`,
    };
  }
}

/**
 * Send an order‑status notification to the customer (and optionally
 * the delivery partner).
 */
export async function sendOrderNotification(
  payload: OrderNotificationPayload
): Promise<void> {
  const {orderId, orderNumber, customerId, status} = payload;

  const {title, body} = statusToNotification(status, orderNumber);
  const data: Record<string, string> = {
    orderId,
    orderNumber,
    status,
    type: NotificationTypes.ORDER_UPDATE,
  };

  try {
    // Send FCM push to customer
    await sendToUser(customerId, title, body, data);

    // Create in‑app notification doc
    await createNotificationDoc(
      customerId,
      title,
      body,
      NotificationTypes.ORDER_UPDATE,
      data
    );

    logger.info(
      `Order notification sent for order ${orderId} status=${status}`
    );
  } catch (error) {
    logger.error(`Failed to send order notification for ${orderId}`, error);
  }
}
