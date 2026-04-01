/**
 * Firestore trigger – fires when a new review document is created.
 *
 * Reads the target's current averageRating and totalRatings, computes
 * the new running average, and updates the target document (restaurant
 * or delivery partner user doc).
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections} from "../utils/constants";

const logger = functions.logger;

export const onReviewCreated = functions.firestore
  .document(`${Collections.REVIEWS}/{reviewId}`)
  .onCreate(async (snapshot) => {
    const reviewData = snapshot.data();
    const reviewId = snapshot.id;

    const targetType = reviewData.targetType as string; // "restaurant" | "deliveryPartner"
    const targetId = reviewData.targetId as string;
    const newRating = reviewData.rating as number;

    if (!targetId || !targetType || typeof newRating !== "number") {
      logger.warn(`Review ${reviewId} is missing required fields`);
      return;
    }

    const db = admin.firestore();

    // Determine target collection
    const targetCollection =
      targetType === "restaurant" ? Collections.RESTAURANTS : Collections.USERS;

    const targetRef = db.collection(targetCollection).doc(targetId);

    try {
      await db.runTransaction(async (txn) => {
        const targetDoc = await txn.get(targetRef);
        if (!targetDoc.exists) {
          logger.warn(
            `Target ${targetType}/${targetId} not found for review ${reviewId}`
          );
          return;
        }

        const targetData = targetDoc.data()!;
        const currentAverage = (targetData.averageRating as number) || 0;
        const currentTotal = (targetData.totalRatings as number) || 0;

        // Running average: new_avg = (old_avg * old_count + new_rating) / (old_count + 1)
        const newTotal = currentTotal + 1;
        const newAverage =
          (currentAverage * currentTotal + newRating) / newTotal;

        txn.update(targetRef, {
          averageRating: Math.round(newAverage * 100) / 100,
          totalRatings: newTotal,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        logger.info(
          `Updated ${targetType} ${targetId}: rating ${currentAverage} -> ` +
            `${newAverage.toFixed(2)} (${newTotal} reviews)`
        );
      });
    } catch (error) {
      logger.error(
        `Error updating rating for ${targetType}/${targetId}`,
        error
      );
      throw error;
    }
  });
