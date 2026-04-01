/**
 * FCM helper functions for sending push notifications and creating
 * in‑app notification documents.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections, NotificationType} from "../utils/constants";

const logger = functions.logger;

/**
 * Send an FCM notification to a specific user by looking up their
 * fcmTokens array in the users collection.
 *
 * Returns the number of tokens that were successfully messaged.
 */
export async function sendToUser(
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<number> {
  const db = admin.firestore();
  const userDoc = await db.collection(Collections.USERS).doc(userId).get();

  if (!userDoc.exists) {
    logger.warn(`sendToUser: user ${userId} not found`);
    return 0;
  }

  const userData = userDoc.data();
  const tokens: string[] = userData?.fcmTokens ?? [];

  if (tokens.length === 0) {
    logger.info(`sendToUser: no FCM tokens for user ${userId}`);
    return 0;
  }

  const message: admin.messaging.MulticastMessage = {
    notification: {title, body},
    data: data ?? {},
    tokens,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);

    // Clean up stale tokens
    const staleTokens: string[] = [];
    response.responses.forEach((resp, idx) => {
      if (
        !resp.success &&
        resp.error &&
        (resp.error.code === "messaging/invalid-registration-token" ||
          resp.error.code === "messaging/registration-token-not-registered")
      ) {
        staleTokens.push(tokens[idx]);
      }
    });

    if (staleTokens.length > 0) {
      await db
        .collection(Collections.USERS)
        .doc(userId)
        .update({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...staleTokens),
        });
      logger.info(
        `Removed ${staleTokens.length} stale tokens for user ${userId}`
      );
    }

    logger.info(
      `sendToUser: ${response.successCount}/${tokens.length} sent to ${userId}`
    );
    return response.successCount;
  } catch (error) {
    logger.error(`sendToUser failed for ${userId}`, error);
    return 0;
  }
}

/**
 * Send an FCM notification to a topic (e.g. "promotions", "all_users").
 */
export async function sendToTopic(
  topic: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<boolean> {
  const message: admin.messaging.Message = {
    notification: {title, body},
    data: data ?? {},
    topic,
  };

  try {
    const messageId = await admin.messaging().send(message);
    logger.info(`sendToTopic: sent to topic '${topic}' (${messageId})`);
    return true;
  } catch (error) {
    logger.error(`sendToTopic failed for topic '${topic}'`, error);
    return false;
  }
}

/**
 * Create a notification document in the notifications collection
 * so users can see in-app notification history.
 */
export async function createNotificationDoc(
  userId: string,
  title: string,
  body: string,
  type: NotificationType,
  data?: Record<string, string>
): Promise<string> {
  const db = admin.firestore();

  const notifData: Record<string, unknown> = {
    userId,
    title,
    body,
    type,
    data: data ?? {},
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const docRef = await db.collection(Collections.NOTIFICATIONS).add(notifData);
  logger.info(`Notification doc created: ${docRef.id} for user ${userId}`);
  return docRef.id;
}
