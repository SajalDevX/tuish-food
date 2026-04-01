/**
 * Auth trigger – runs when a Firebase Auth user is deleted.
 * Cleans up the user's Firestore data: the user document and
 * its 'addresses' subcollection.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections, SubCollections} from "../utils/constants";

const logger = functions.logger;

/**
 * Recursively delete all documents in a subcollection.
 */
async function deleteSubcollection(
  docRef: admin.firestore.DocumentReference,
  subcollectionName: string
): Promise<number> {
  const snapshot = await docRef.collection(subcollectionName).get();
  if (snapshot.empty) return 0;

  const batch = admin.firestore().batch();
  let count = 0;
  for (const doc of snapshot.docs) {
    batch.delete(doc.ref);
    count++;
  }
  await batch.commit();
  return count;
}

export const onUserDeleted = functions.auth.user().onDelete(async (user) => {
  const {uid} = user;
  logger.info(`User deleted from Auth: ${uid}. Cleaning up Firestore data.`);

  const db = admin.firestore();
  const userRef = db.collection(Collections.USERS).doc(uid);

  try {
    // 1. Delete the 'addresses' subcollection
    const addressCount = await deleteSubcollection(
      userRef,
      SubCollections.ADDRESSES
    );
    logger.info(
      `Deleted ${addressCount} address documents for user ${uid}`
    );

    // 2. Delete the user document itself
    const userDoc = await userRef.get();
    if (userDoc.exists) {
      await userRef.delete();
      logger.info(`Deleted user document for ${uid}`);
    } else {
      logger.warn(`No Firestore user document found for ${uid}`);
    }

    // 3. Delete notifications for this user
    const notifSnapshot = await db
      .collection(Collections.NOTIFICATIONS)
      .where("userId", "==", uid)
      .get();

    if (!notifSnapshot.empty) {
      const batch = db.batch();
      for (const doc of notifSnapshot.docs) {
        batch.delete(doc.ref);
      }
      await batch.commit();
      logger.info(
        `Deleted ${notifSnapshot.size} notification documents for user ${uid}`
      );
    }

    logger.info(`Cleanup complete for user ${uid}`);
  } catch (error) {
    logger.error(`Error cleaning up data for user ${uid}`, error);
    throw error;
  }
});
