/**
 * Scheduled function – expires restaurant subscription grace periods.
 *
 * Runs daily. Finds restaurants where isSubscriptionValid is true but
 * the grace deadline has passed, and sets isSubscriptionValid to false.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections} from "../utils/constants";

const logger = functions.logger;

export const expireGracePeriods = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    const snapshot = await db
      .collection(Collections.RESTAURANTS)
      .where("isSubscriptionValid", "==", true)
      .where("subscriptionGraceDeadline", "<=", now)
      .get();

    if (snapshot.empty) {
      logger.info("No grace periods to expire.");
      return;
    }

    const batch = db.batch();
    let count = 0;

    for (const doc of snapshot.docs) {
      batch.update(doc.ref, {
        isSubscriptionValid: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      count++;
    }

    await batch.commit();
    logger.info(`Expired grace periods for ${count} restaurant(s).`);
  });
