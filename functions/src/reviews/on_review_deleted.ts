/**
 * Firestore trigger – fires when a review document is deleted.
 *
 * Recalculates the target's averageRating by reversing the deleted
 * review from the running average.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections} from "../utils/constants";

const logger = functions.logger;

export const onReviewDeleted = functions.firestore
  .document(`${Collections.REVIEWS}/{reviewId}`)
  .onDelete(async (snapshot) => {
    const reviewData = snapshot.data();
    const reviewId = snapshot.id;

    const targetType = reviewData.targetType as string;
    const targetId = reviewData.targetId as string;
    const deletedRating = reviewData.rating as number;

    if (!targetId || !targetType || typeof deletedRating !== "number") {
      logger.warn(
        `Deleted review ${reviewId} is missing required fields – skipping`
      );
      return;
    }

    const db = admin.firestore();

    const targetCollection =
      targetType === "restaurant" ? Collections.RESTAURANTS : Collections.USERS;

    const targetRef = db.collection(targetCollection).doc(targetId);

    try {
      await db.runTransaction(async (txn) => {
        const targetDoc = await txn.get(targetRef);
        if (!targetDoc.exists) {
          logger.warn(
            `Target ${targetType}/${targetId} not found after review deletion`
          );
          return;
        }

        const targetData = targetDoc.data()!;
        const currentAverage = (targetData.averageRating as number) || 0;
        const currentTotal = (targetData.totalRatings as number) || 0;

        if (currentTotal <= 1) {
          // This was the only review – reset to zero
          txn.update(targetRef, {
            averageRating: 0,
            totalRatings: 0,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          logger.info(
            `Reset ${targetType} ${targetId} rating to 0 (last review removed)`
          );
          return;
        }

        // Reverse the running average:
        // new_avg = (old_avg * old_count - deleted_rating) / (old_count - 1)
        const newTotal = currentTotal - 1;
        const newAverage =
          (currentAverage * currentTotal - deletedRating) / newTotal;

        txn.update(targetRef, {
          averageRating: Math.max(Math.round(newAverage * 100) / 100, 0),
          totalRatings: newTotal,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        logger.info(
          `Updated ${targetType} ${targetId} after deletion: ` +
            `rating ${currentAverage} -> ${newAverage.toFixed(2)} (${newTotal} reviews)`
        );
      });
    } catch (error) {
      logger.error(
        `Error recalculating rating for ${targetType}/${targetId}`,
        error
      );
      throw error;
    }
  });
