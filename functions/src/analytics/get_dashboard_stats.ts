/**
 * Callable function (admin only) – returns dashboard statistics:
 * total orders, revenue, active users, and average delivery time
 * for a given time period.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections, UserRoles, OrderStatuses} from "../utils/constants";

const logger = functions.logger;

interface DashboardStatsInput {
  /** ISO date string for period start, e.g. "2026-03-01" */
  startDate: string;
  /** ISO date string for period end, e.g. "2026-03-28" */
  endDate: string;
}

interface DashboardStats {
  totalOrders: number;
  completedOrders: number;
  cancelledOrders: number;
  totalRevenue: number;
  averageOrderValue: number;
  activeUsers: number;
  activeDeliveryPartners: number;
  averageDeliveryTimeMinutes: number;
}

export const getDashboardStats = functions.https.onCall(
  async (data: DashboardStatsInput, context): Promise<DashboardStats> => {
    // ── Auth check ──────────────────────────────────────────────────────
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in."
      );
    }
    if (context.auth.token.role !== UserRoles.ADMIN) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can access dashboard stats."
      );
    }

    const {startDate, endDate} = data;
    if (!startDate || !endDate) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "startDate and endDate are required."
      );
    }

    const start = new Date(`${startDate}T00:00:00Z`);
    const end = new Date(`${endDate}T23:59:59.999Z`);

    if (isNaN(start.getTime()) || isNaN(end.getTime())) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "startDate and endDate must be valid ISO date strings."
      );
    }

    const db = admin.firestore();

    try {
      // ── Orders in range ─────────────────────────────────────────────
      const ordersSnapshot = await db
        .collection(Collections.ORDERS)
        .where(
          "createdAt",
          ">=",
          admin.firestore.Timestamp.fromDate(start)
        )
        .where(
          "createdAt",
          "<=",
          admin.firestore.Timestamp.fromDate(end)
        )
        .get();

      let totalOrders = 0;
      let completedOrders = 0;
      let cancelledOrders = 0;
      let totalRevenue = 0;
      let totalDeliveryTimeMs = 0;
      let deliveriesWithTime = 0;
      const uniqueCustomers = new Set<string>();
      const uniquePartners = new Set<string>();

      for (const doc of ordersSnapshot.docs) {
        const d = doc.data();
        totalOrders++;

        const status = d.status as string;
        const customerId = d.customerId as string;
        const partnerId = d.deliveryPartnerId as string | undefined;

        if (customerId) uniqueCustomers.add(customerId);
        if (partnerId) uniquePartners.add(partnerId);

        if (status === OrderStatuses.DELIVERED) {
          completedOrders++;
          totalRevenue += (d.totalAmount as number) || 0;

          // Calculate delivery time
          const createdAt = d.createdAt?.toDate?.() as Date | undefined;
          const actualDelivery = d.actualDeliveryTime?.toDate?.() as
            | Date
            | undefined;
          if (createdAt && actualDelivery) {
            totalDeliveryTimeMs +=
              actualDelivery.getTime() - createdAt.getTime();
            deliveriesWithTime++;
          }
        } else if (status === OrderStatuses.CANCELLED) {
          cancelledOrders++;
        }
      }

      const averageDeliveryTimeMinutes =
        deliveriesWithTime > 0
          ? Math.round(totalDeliveryTimeMs / deliveriesWithTime / 60000)
          : 0;

      const averageOrderValue =
        completedOrders > 0
          ? Math.round((totalRevenue / completedOrders) * 100) / 100
          : 0;

      const stats: DashboardStats = {
        totalOrders,
        completedOrders,
        cancelledOrders,
        totalRevenue: Math.round(totalRevenue * 100) / 100,
        averageOrderValue,
        activeUsers: uniqueCustomers.size,
        activeDeliveryPartners: uniquePartners.size,
        averageDeliveryTimeMinutes,
      };

      logger.info("Dashboard stats computed", stats);
      return stats;
    } catch (error) {
      logger.error("Error computing dashboard stats", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to compute dashboard stats."
      );
    }
  }
);
