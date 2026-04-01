/**
 * Scheduled function – runs daily at 1 AM IST.
 * Deactivates any promotions whose validUntil date has passed.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections} from "../utils/constants";

const logger = functions.logger;

export const expirePromotions = functions.pubsub
  .schedule("every day 01:00")
  .timeZone("Asia/Kolkata")
  .onRun(async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    logger.info("Starting expired promotions cleanup");

    try {
      // Query active promotions with a validUntil in the past
      const snapshot = await db
        .collection(Collections.PROMOTIONS)
        .where("isActive", "==", true)
        .where("validUntil", "<=", now)
        .get();

      if (snapshot.empty) {
        logger.info("No expired promotions found");
        return;
      }

      // Batch deactivate
      const batchSize = 450;
      const docs = snapshot.docs;

      for (let i = 0; i < docs.length; i += batchSize) {
        const batch = db.batch();
        const chunk = docs.slice(i, i + batchSize);

        for (const doc of chunk) {
          batch.update(doc.ref, {
            isActive: false,
            deactivatedAt: admin.firestore.FieldValue.serverTimestamp(),
            deactivationReason: "expired",
          });
        }

        await batch.commit();
      }

      logger.info(`Deactivated ${docs.length} expired promotions`);
    } catch (error) {
      logger.error("Error expiring promotions", error);
      throw error;
    }
  });
