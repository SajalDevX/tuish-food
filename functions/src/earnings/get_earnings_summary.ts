/**
 * Callable function – returns aggregated earnings for a delivery partner
 * over a given period (day / week / month).
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections, UserRoles} from "../utils/constants";

const logger = functions.logger;

interface GetEarningsInput {
  /** Period type: "day" | "week" | "month" */
  period: string;
  /** ISO string for the target period, e.g. "2026-03-28", "2026-W13", "2026-03" */
  periodValue: string;
  /** Optional: admin can query for another partner */
  deliveryPartnerId?: string;
}

interface EarningsSummary {
  deliveryPartnerId: string;
  period: string;
  periodValue: string;
  totalDeliveryFee: number;
  totalTip: number;
  totalBonus: number;
  totalEarned: number;
  deliveryCount: number;
  averagePerDelivery: number;
  isPaidOut: boolean;
}

export const getEarningsSummary = functions.https.onCall(
  async (data: GetEarningsInput, context): Promise<EarningsSummary> => {
    // ── Auth check ──────────────────────────────────────────────────────
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in."
      );
    }

    const {period, periodValue} = data;
    const callerRole = context.auth.token.role as string | undefined;
    const callerUid = context.auth.uid;

    // Determine which partner to query
    let targetPartnerId = callerUid;
    if (data.deliveryPartnerId && data.deliveryPartnerId !== callerUid) {
      // Only admins can view other partners' earnings
      if (callerRole !== UserRoles.ADMIN) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Only admins can view other partners' earnings."
        );
      }
      targetPartnerId = data.deliveryPartnerId;
    }

    if (!period || !["day", "week", "month"].includes(period)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "period must be one of: day, week, month."
      );
    }
    if (!periodValue || typeof periodValue !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "periodValue is required."
      );
    }

    const db = admin.firestore();

    try {
      let query: admin.firestore.Query = db
        .collection(Collections.EARNINGS)
        .where("deliveryPartnerId", "==", targetPartnerId);

      // Build date range based on period
      if (period === "day") {
        // periodValue = "2026-03-28"
        const dayStart = new Date(`${periodValue}T00:00:00Z`);
        const dayEnd = new Date(`${periodValue}T23:59:59.999Z`);
        query = query
          .where("date", ">=", admin.firestore.Timestamp.fromDate(dayStart))
          .where("date", "<=", admin.firestore.Timestamp.fromDate(dayEnd));
      } else if (period === "week") {
        // periodValue = "2026-W13" -> filter by week field
        query = query.where("week", "==", periodValue);
      } else {
        // periodValue = "2026-03" -> filter by month field
        query = query.where("month", "==", periodValue);
      }

      const snapshot = await query.get();

      let totalDeliveryFee = 0;
      let totalTip = 0;
      let totalBonus = 0;
      let totalEarned = 0;
      let allPaidOut = true;

      for (const doc of snapshot.docs) {
        const d = doc.data();
        totalDeliveryFee += (d.deliveryFee as number) || 0;
        totalTip += (d.tip as number) || 0;
        totalBonus += (d.bonus as number) || 0;
        totalEarned += (d.totalEarned as number) || 0;
        if (!(d.isPaidOut as boolean)) {
          allPaidOut = false;
        }
      }

      const deliveryCount = snapshot.size;

      logger.info(
        `Earnings summary for ${targetPartnerId}: ${period}=${periodValue}, ` +
          `deliveries=${deliveryCount}, total=₹${totalEarned}`
      );

      return {
        deliveryPartnerId: targetPartnerId,
        period,
        periodValue,
        totalDeliveryFee: Math.round(totalDeliveryFee * 100) / 100,
        totalTip: Math.round(totalTip * 100) / 100,
        totalBonus: Math.round(totalBonus * 100) / 100,
        totalEarned: Math.round(totalEarned * 100) / 100,
        deliveryCount,
        averagePerDelivery:
          deliveryCount > 0
            ? Math.round((totalEarned / deliveryCount) * 100) / 100
            : 0,
        isPaidOut: deliveryCount > 0 && allPaidOut,
      };
    } catch (error) {
      logger.error("Error getting earnings summary", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to retrieve earnings summary."
      );
    }
  }
);
