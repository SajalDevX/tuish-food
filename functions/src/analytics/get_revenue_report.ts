/**
 * Callable function (admin only) – returns daily revenue for a date range.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections, UserRoles, OrderStatuses} from "../utils/constants";

const logger = functions.logger;

interface RevenueReportInput {
  /** ISO date, e.g. "2026-03-01" */
  startDate: string;
  /** ISO date, e.g. "2026-03-28" */
  endDate: string;
}

interface DailyRevenue {
  date: string;
  revenue: number;
  orderCount: number;
  averageOrderValue: number;
}

interface RevenueReport {
  startDate: string;
  endDate: string;
  totalRevenue: number;
  totalOrders: number;
  dailyRevenue: DailyRevenue[];
}

export const getRevenueReport = functions.https.onCall(
  async (data: RevenueReportInput, context): Promise<RevenueReport> => {
    // ── Auth ─────────────────────────────────────────────────────────────
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in."
      );
    }
    if (context.auth.token.role !== UserRoles.ADMIN) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can access revenue reports."
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
        "Invalid date format."
      );
    }

    const db = admin.firestore();

    try {
      const ordersSnapshot = await db
        .collection(Collections.ORDERS)
        .where("status", "==", OrderStatuses.DELIVERED)
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

      // Aggregate by day
      const dailyMap = new Map<
        string,
        {revenue: number; count: number}
      >();

      let totalRevenue = 0;
      let totalOrders = 0;

      for (const doc of ordersSnapshot.docs) {
        const d = doc.data();
        const amount = (d.totalAmount as number) || 0;
        const createdAt = d.createdAt?.toDate?.() as Date | undefined;
        if (!createdAt) continue;

        const dayKey = createdAt.toISOString().substring(0, 10);
        const existing = dailyMap.get(dayKey) || {revenue: 0, count: 0};
        existing.revenue += amount;
        existing.count += 1;
        dailyMap.set(dayKey, existing);

        totalRevenue += amount;
        totalOrders++;
      }

      // Build sorted daily array
      const dailyRevenue: DailyRevenue[] = Array.from(dailyMap.entries())
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([date, {revenue, count}]) => ({
          date,
          revenue: Math.round(revenue * 100) / 100,
          orderCount: count,
          averageOrderValue:
            count > 0 ? Math.round((revenue / count) * 100) / 100 : 0,
        }));

      logger.info(
        `Revenue report: ${startDate} to ${endDate}, ` +
          `total=₹${totalRevenue.toFixed(2)}, orders=${totalOrders}`
      );

      return {
        startDate,
        endDate,
        totalRevenue: Math.round(totalRevenue * 100) / 100,
        totalOrders,
        dailyRevenue,
      };
    } catch (error) {
      logger.error("Error generating revenue report", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to generate revenue report."
      );
    }
  }
);
