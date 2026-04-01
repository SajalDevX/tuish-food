/**
 * Scheduled function – runs daily at 2 AM IST.
 * Aggregates the previous day's orders into a summary document
 * stored at app_config/daily_summaries/{date}.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections, OrderStatuses, AppConfigDocs} from "../utils/constants";

const logger = functions.logger;

export const dailyAggregation = functions.pubsub
  .schedule("every day 02:00")
  .timeZone("Asia/Kolkata")
  .onRun(async () => {
    const db = admin.firestore();

    // Calculate yesterday's date range (IST offset = +5:30)
    const now = new Date();
    // Go back one day
    const yesterday = new Date(now);
    yesterday.setDate(yesterday.getDate() - 1);
    const dateStr = yesterday.toISOString().substring(0, 10);

    const dayStart = new Date(`${dateStr}T00:00:00+05:30`);
    const dayEnd = new Date(`${dateStr}T23:59:59.999+05:30`);

    logger.info(`Running daily aggregation for ${dateStr}`);

    try {
      const ordersSnapshot = await db
        .collection(Collections.ORDERS)
        .where(
          "createdAt",
          ">=",
          admin.firestore.Timestamp.fromDate(dayStart)
        )
        .where(
          "createdAt",
          "<=",
          admin.firestore.Timestamp.fromDate(dayEnd)
        )
        .get();

      let totalOrders = 0;
      let completedOrders = 0;
      let cancelledOrders = 0;
      let totalRevenue = 0;
      let totalDeliveryFee = 0;
      let totalServiceFee = 0;
      let totalTax = 0;
      let totalDiscount = 0;
      let totalDeliveryTimeMs = 0;
      let deliveriesWithTime = 0;
      const uniqueCustomers = new Set<string>();
      const uniqueRestaurants = new Set<string>();

      for (const doc of ordersSnapshot.docs) {
        const d = doc.data();
        totalOrders++;

        const status = d.status as string;
        const customerId = d.customerId as string;
        const restaurantId = d.restaurantId as string;

        if (customerId) uniqueCustomers.add(customerId);
        if (restaurantId) uniqueRestaurants.add(restaurantId);

        if (status === OrderStatuses.DELIVERED) {
          completedOrders++;
          totalRevenue += (d.totalAmount as number) || 0;
          totalDeliveryFee += (d.deliveryFee as number) || 0;
          totalServiceFee += (d.serviceFee as number) || 0;
          totalTax += (d.tax as number) || 0;
          totalDiscount += (d.discount as number) || 0;

          const createdAt = d.createdAt?.toDate?.() as Date | undefined;
          const deliveredAt = d.actualDeliveryTime?.toDate?.() as
            | Date
            | undefined;
          if (createdAt && deliveredAt) {
            totalDeliveryTimeMs +=
              deliveredAt.getTime() - createdAt.getTime();
            deliveriesWithTime++;
          }
        } else if (status === OrderStatuses.CANCELLED) {
          cancelledOrders++;
        }
      }

      const summary: Record<string, unknown> = {
        date: dateStr,
        totalOrders,
        completedOrders,
        cancelledOrders,
        totalRevenue: Math.round(totalRevenue * 100) / 100,
        totalDeliveryFee: Math.round(totalDeliveryFee * 100) / 100,
        totalServiceFee: Math.round(totalServiceFee * 100) / 100,
        totalTax: Math.round(totalTax * 100) / 100,
        totalDiscount: Math.round(totalDiscount * 100) / 100,
        uniqueCustomers: uniqueCustomers.size,
        uniqueRestaurants: uniqueRestaurants.size,
        averageOrderValue:
          completedOrders > 0
            ? Math.round((totalRevenue / completedOrders) * 100) / 100
            : 0,
        averageDeliveryTimeMinutes:
          deliveriesWithTime > 0
            ? Math.round(totalDeliveryTimeMs / deliveriesWithTime / 60000)
            : 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Store under app_config/settings/daily_summaries/{date}
      await db
        .collection(Collections.APP_CONFIG)
        .doc(AppConfigDocs.SETTINGS)
        .collection("daily_summaries")
        .doc(dateStr)
        .set(summary);

      logger.info(
        `Daily aggregation for ${dateStr} complete: ` +
          `${totalOrders} orders, ₹${totalRevenue.toFixed(2)} revenue`
      );
    } catch (error) {
      logger.error(`Error in daily aggregation for ${dateStr}`, error);
      throw error;
    }
  });
