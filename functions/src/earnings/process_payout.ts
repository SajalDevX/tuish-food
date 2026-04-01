/**
 * Scheduled function – runs weekly (every Monday at 3 AM).
 * Queries all unpaid earnings, groups them by delivery partner,
 * and marks them as paid.
 *
 * In a production system this would integrate with a payment provider;
 * here we create a payout summary and flip the isPaidOut flag.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections, NotificationTypes} from "../utils/constants";
import {createNotificationDoc} from "../notifications/fcm_helpers";

const logger = functions.logger;

export const processPayout = functions.pubsub
  .schedule("every monday 03:00")
  .timeZone("Asia/Kolkata")
  .onRun(async () => {
    const db = admin.firestore();

    logger.info("Starting weekly payout processing");

    try {
      // 1. Query all unpaid earnings
      const unpaidSnapshot = await db
        .collection(Collections.EARNINGS)
        .where("isPaidOut", "==", false)
        .get();

      if (unpaidSnapshot.empty) {
        logger.info("No unpaid earnings to process");
        return;
      }

      // 2. Group by delivery partner
      const partnerEarnings = new Map<
        string,
        {total: number; docIds: string[]}
      >();

      for (const doc of unpaidSnapshot.docs) {
        const data = doc.data();
        const partnerId = data.deliveryPartnerId as string;
        const earned = (data.totalEarned as number) || 0;

        const existing = partnerEarnings.get(partnerId) || {
          total: 0,
          docIds: [],
        };
        existing.total += earned;
        existing.docIds.push(doc.id);
        partnerEarnings.set(partnerId, existing);
      }

      logger.info(
        `Processing payouts for ${partnerEarnings.size} delivery partners ` +
          `(${unpaidSnapshot.size} earnings records)`
      );

      // 3. Process each partner – batch update their earnings to isPaidOut=true
      for (const [partnerId, info] of partnerEarnings.entries()) {
        // Firestore batch limit is 500 – chunk if needed
        const chunks: string[][] = [];
        for (let i = 0; i < info.docIds.length; i += 450) {
          chunks.push(info.docIds.slice(i, i + 450));
        }

        for (const chunk of chunks) {
          const batch = db.batch();
          for (const docId of chunk) {
            batch.update(db.collection(Collections.EARNINGS).doc(docId), {
              isPaidOut: true,
              paidOutAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
          await batch.commit();
        }

        // Notify the partner
        const payoutAmount = Math.round(info.total * 100) / 100;
        await createNotificationDoc(
          partnerId,
          "Payout Processed",
          `Your weekly payout of ₹${payoutAmount.toFixed(
            2
          )} for ${info.docIds.length} deliveries has been processed.`,
          NotificationTypes.EARNINGS,
          {amount: payoutAmount.toString(), deliveries: info.docIds.length.toString()}
        );

        logger.info(
          `Payout processed for partner ${partnerId}: ₹${payoutAmount} ` +
            `(${info.docIds.length} deliveries)`
        );
      }

      logger.info("Weekly payout processing complete");
    } catch (error) {
      logger.error("Error in weekly payout processing", error);
      throw error;
    }
  });
