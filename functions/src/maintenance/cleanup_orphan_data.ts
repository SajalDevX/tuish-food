/**
 * Scheduled function – runs weekly (every Sunday at 5 AM IST).
 * Checks for orphaned data and cleans it up:
 *  - Orders referencing non‑existent users
 *  - Earnings referencing non‑existent orders
 *  - Notifications for non‑existent users
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections} from "../utils/constants";

const logger = functions.logger;

/**
 * Check whether a document exists.
 */
async function docExists(
  db: admin.firestore.Firestore,
  collection: string,
  docId: string
): Promise<boolean> {
  const doc = await db.collection(collection).doc(docId).get();
  return doc.exists;
}

export const cleanupOrphanData = functions.pubsub
  .schedule("every sunday 05:00")
  .timeZone("Asia/Kolkata")
  .onRun(async () => {
    const db = admin.firestore();
    let totalOrphans = 0;

    logger.info("Starting weekly orphan data cleanup");

    try {
      // ── 1. Orders with non‑existent customers ─────────────────────────
      const ordersSnapshot = await db
        .collection(Collections.ORDERS)
        .limit(1000) // Process in manageable chunks
        .get();

      const orphanOrderIds: string[] = [];
      const checkedUsers = new Map<string, boolean>();

      for (const doc of ordersSnapshot.docs) {
        const customerId = doc.data().customerId as string;
        if (!customerId) continue;

        // Cache user existence checks
        if (!checkedUsers.has(customerId)) {
          const exists = await docExists(db, Collections.USERS, customerId);
          checkedUsers.set(customerId, exists);
        }

        if (!checkedUsers.get(customerId)) {
          orphanOrderIds.push(doc.id);
        }
      }

      if (orphanOrderIds.length > 0) {
        logger.warn(
          `Found ${orphanOrderIds.length} orders with non-existent customers`
        );
        // Flag them instead of deleting – admins should review
        for (let i = 0; i < orphanOrderIds.length; i += 450) {
          const batch = db.batch();
          const chunk = orphanOrderIds.slice(i, i + 450);
          for (const orderId of chunk) {
            batch.update(
              db.collection(Collections.ORDERS).doc(orderId),
              {
                _orphaned: true,
                _orphanReason: "customer_not_found",
                _orphanDetectedAt:
                  admin.firestore.FieldValue.serverTimestamp(),
              }
            );
          }
          await batch.commit();
        }
        totalOrphans += orphanOrderIds.length;
      }

      // ── 2. Earnings with non‑existent orders ─────────────────────────
      const earningsSnapshot = await db
        .collection(Collections.EARNINGS)
        .limit(1000)
        .get();

      const orphanEarningIds: string[] = [];
      const checkedOrders = new Map<string, boolean>();

      for (const doc of earningsSnapshot.docs) {
        const orderId = doc.data().orderId as string;
        if (!orderId) continue;

        if (!checkedOrders.has(orderId)) {
          const exists = await docExists(db, Collections.ORDERS, orderId);
          checkedOrders.set(orderId, exists);
        }

        if (!checkedOrders.get(orderId)) {
          orphanEarningIds.push(doc.id);
        }
      }

      if (orphanEarningIds.length > 0) {
        logger.warn(
          `Found ${orphanEarningIds.length} earnings with non-existent orders`
        );
        for (let i = 0; i < orphanEarningIds.length; i += 450) {
          const batch = db.batch();
          const chunk = orphanEarningIds.slice(i, i + 450);
          for (const earningId of chunk) {
            batch.update(
              db.collection(Collections.EARNINGS).doc(earningId),
              {
                _orphaned: true,
                _orphanReason: "order_not_found",
                _orphanDetectedAt:
                  admin.firestore.FieldValue.serverTimestamp(),
              }
            );
          }
          await batch.commit();
        }
        totalOrphans += orphanEarningIds.length;
      }

      // ── 3. Notifications for non‑existent users ──────────────────────
      const notifSnapshot = await db
        .collection(Collections.NOTIFICATIONS)
        .limit(1000)
        .get();

      const orphanNotifIds: string[] = [];

      for (const doc of notifSnapshot.docs) {
        const userId = doc.data().userId as string;
        if (!userId) continue;

        if (!checkedUsers.has(userId)) {
          const exists = await docExists(db, Collections.USERS, userId);
          checkedUsers.set(userId, exists);
        }

        if (!checkedUsers.get(userId)) {
          orphanNotifIds.push(doc.id);
        }
      }

      if (orphanNotifIds.length > 0) {
        logger.info(
          `Deleting ${orphanNotifIds.length} notifications for non-existent users`
        );
        for (let i = 0; i < orphanNotifIds.length; i += 450) {
          const batch = db.batch();
          const chunk = orphanNotifIds.slice(i, i + 450);
          for (const notifId of chunk) {
            batch.delete(
              db.collection(Collections.NOTIFICATIONS).doc(notifId)
            );
          }
          await batch.commit();
        }
        totalOrphans += orphanNotifIds.length;
      }

      logger.info(
        `Orphan cleanup complete: ${totalOrphans} orphaned records found and processed`
      );
    } catch (error) {
      logger.error("Error in orphan data cleanup", error);
      throw error;
    }
  });
