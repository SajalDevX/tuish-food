/**
 * Exported helper – finds and assigns the nearest available delivery
 * partner to an order.  Called from on_order_created.
 *
 * Logic:
 *  1. Look up the restaurant's coordinates.
 *  2. Query delivery_locations for partners who are online and have
 *     no active order.
 *  3. Filter by MAX_DELIVERY_RADIUS_KM using Haversine.
 *  4. Assign the nearest partner.
 *  5. Update the order document and the partner's delivery_locations
 *     doc.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections, Delivery} from "../utils/constants";
import {haversineDistance} from "../utils/geo_utils";

const logger = functions.logger;

export interface AssignmentResult {
  assigned: boolean;
  deliveryPartnerId?: string;
  deliveryPartnerName?: string;
}

/**
 * Attempt to assign a delivery partner to the given order.
 */
export async function assignDeliveryPartner(
  orderId: string,
  restaurantId: string
): Promise<AssignmentResult> {
  const db = admin.firestore();

  // ── 1. Get restaurant location ────────────────────────────────────────
  const restaurantDoc = await db
    .collection(Collections.RESTAURANTS)
    .doc(restaurantId)
    .get();

  if (!restaurantDoc.exists) {
    logger.warn(`Restaurant ${restaurantId} not found for order ${orderId}`);
    return {assigned: false};
  }

  const restaurantData = restaurantDoc.data()!;
  const address = restaurantData.address as
    | {location?: admin.firestore.GeoPoint}
    | undefined;
  const geoPoint = address?.location;

  if (!geoPoint) {
    logger.warn(`Restaurant ${restaurantId} has no location data`);
    return {assigned: false};
  }

  const restLat = geoPoint.latitude;
  const restLon = geoPoint.longitude;

  // ── 2. Query online partners without an active order ──────────────────
  const locSnapshot = await db
    .collection(Collections.DELIVERY_LOCATIONS)
    .where("isOnline", "==", true)
    .where("hasActiveOrder", "==", false)
    .get();

  if (locSnapshot.empty) {
    logger.info(`No available delivery partners for order ${orderId}`);
    return {assigned: false};
  }

  // ── 3. Filter by distance & find nearest ──────────────────────────────
  let nearestId: string | null = null;
  let nearestName: string | null = null;
  let nearestDistance = Infinity;

  for (const doc of locSnapshot.docs) {
    const data = doc.data();
    const partnerGeo = data.location as admin.firestore.GeoPoint | undefined;
    if (!partnerGeo) continue;

    const distance = haversineDistance(
      restLat,
      restLon,
      partnerGeo.latitude,
      partnerGeo.longitude
    );

    if (
      distance <= Delivery.MAX_DELIVERY_RADIUS_KM &&
      distance < nearestDistance
    ) {
      nearestDistance = distance;
      nearestId = doc.id;
      nearestName = (data.displayName as string) ?? null;
    }
  }

  if (!nearestId) {
    logger.info(
      `No delivery partners within ${Delivery.MAX_DELIVERY_RADIUS_KM}km for order ${orderId}`
    );
    return {assigned: false};
  }

  // ── 4. Assign partner using a transaction ─────────────────────────────
  try {
    await db.runTransaction(async (txn) => {
      const partnerLocRef = db
        .collection(Collections.DELIVERY_LOCATIONS)
        .doc(nearestId!);
      const partnerLocDoc = await txn.get(partnerLocRef);

      // Re-check availability inside transaction
      if (
        !partnerLocDoc.exists ||
        partnerLocDoc.data()?.hasActiveOrder === true
      ) {
        throw new Error("Partner no longer available");
      }

      const orderRef = db.collection(Collections.ORDERS).doc(orderId);

      // Update delivery_locations doc
      txn.update(partnerLocRef, {
        hasActiveOrder: true,
        activeOrderId: orderId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update order doc with partner info
      txn.update(orderRef, {
        deliveryPartnerId: nearestId,
        deliveryPartnerName: nearestName,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    logger.info(
      `Assigned delivery partner ${nearestId} to order ${orderId} ` +
        `(distance: ${nearestDistance.toFixed(2)}km)`
    );

    return {
      assigned: true,
      deliveryPartnerId: nearestId,
      deliveryPartnerName: nearestName ?? undefined,
    };
  } catch (error) {
    logger.error(
      `Failed to assign partner ${nearestId} to order ${orderId}`,
      error
    );
    return {assigned: false};
  }
}
