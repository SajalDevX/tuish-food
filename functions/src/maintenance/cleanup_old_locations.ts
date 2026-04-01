/**
 * Scheduled function – runs daily at 4 AM IST.
 * Deletes delivery_locations documents where:
 *  - updatedAt is older than 24 hours
 *  - isOnline == false
 *
 * This prevents stale location data from accumulating.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections} from "../utils/constants";

const logger = functions.logger;

export const cleanupOldLocations = functions.pubsub
  .schedule("every day 04:00")
  .timeZone("Asia/Kolkata")
  .onRun(async () => {
    const db = admin.firestore();
    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const cutoff = admin.firestore.Timestamp.fromDate(twentyFourHoursAgo);

    logger.info(
      `Cleaning up stale delivery locations older than ${twentyFourHoursAgo.toISOString()}`
    );

    try {
      const snapshot = await db
        .collection(Collections.DELIVERY_LOCATIONS)
        .where("isOnline", "==", false)
        .where("updatedAt", "<=", cutoff)
        .get();

      if (snapshot.empty) {
        logger.info("No stale delivery locations found");
        return;
      }

      const batchSize = 450;
      const docs = snapshot.docs;

      for (let i = 0; i < docs.length; i += batchSize) {
        const batch = db.batch();
        const chunk = docs.slice(i, i + batchSize);

        for (const doc of chunk) {
          batch.delete(doc.ref);
        }

        await batch.commit();
      }

      logger.info(
        `Deleted ${docs.length} stale delivery location documents`
      );
    } catch (error) {
      logger.error("Error cleaning up old locations", error);
      throw error;
    }
  });
