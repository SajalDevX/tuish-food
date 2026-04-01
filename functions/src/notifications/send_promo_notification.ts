/**
 * Callable function (admin only) – sends a promotional push
 * notification to all users or a filtered subset.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections, UserRoles, NotificationTypes} from "../utils/constants";
import {sendToUser, sendToTopic, createNotificationDoc} from "./fcm_helpers";

const logger = functions.logger;

interface PromoNotificationInput {
  title: string;
  body: string;
  /** Optional: send only to users with this role */
  targetRole?: string;
  /** Optional: send to a specific list of user IDs */
  targetUserIds?: string[];
  /** Optional: additional data payload */
  data?: Record<string, string>;
}

export const sendPromoNotification = functions.https.onCall(
  async (input: PromoNotificationInput, context) => {
    // ── Auth check ──────────────────────────────────────────────────────
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in."
      );
    }

    const callerRole = context.auth.token.role as string | undefined;
    if (callerRole !== UserRoles.ADMIN) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can send promotional notifications."
      );
    }

    // ── Validate input ──────────────────────────────────────────────────
    const {title, body, targetRole, targetUserIds, data} = input;
    if (!title || typeof title !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "title is required."
      );
    }
    if (!body || typeof body !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "body is required."
      );
    }

    const extraData: Record<string, string> = {
      ...data,
      type: NotificationTypes.PROMOTION,
    };

    let sentCount = 0;

    try {
      // Case 1: Specific user IDs
      if (targetUserIds && Array.isArray(targetUserIds) && targetUserIds.length > 0) {
        for (const uid of targetUserIds) {
          const count = await sendToUser(uid, title, body, extraData);
          if (count > 0) sentCount++;
          await createNotificationDoc(
            uid,
            title,
            body,
            NotificationTypes.PROMOTION,
            extraData
          );
        }

        logger.info(
          `Promo notification sent to ${sentCount}/${targetUserIds.length} specified users`
        );
      }
      // Case 2: Filter by role
      else if (targetRole && typeof targetRole === "string") {
        const usersSnapshot = await admin
          .firestore()
          .collection(Collections.USERS)
          .where("role", "==", targetRole)
          .where("isActive", "==", true)
          .get();

        for (const userDoc of usersSnapshot.docs) {
          const count = await sendToUser(userDoc.id, title, body, extraData);
          if (count > 0) sentCount++;
          await createNotificationDoc(
            userDoc.id,
            title,
            body,
            NotificationTypes.PROMOTION,
            extraData
          );
        }

        logger.info(
          `Promo notification sent to ${sentCount}/${usersSnapshot.size} users with role=${targetRole}`
        );
      }
      // Case 3: All users – use topic
      else {
        await sendToTopic("all_users", title, body, extraData);

        // Also create notification docs for all active users
        const allUsersSnapshot = await admin
          .firestore()
          .collection(Collections.USERS)
          .where("isActive", "==", true)
          .get();

        const batch = admin.firestore().batch();
        for (const userDoc of allUsersSnapshot.docs) {
          const notifRef = admin
            .firestore()
            .collection(Collections.NOTIFICATIONS)
            .doc();
          batch.set(notifRef, {
            userId: userDoc.id,
            title,
            body,
            type: NotificationTypes.PROMOTION,
            data: extraData,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();

        sentCount = allUsersSnapshot.size;
        logger.info(
          `Promo notification sent to topic 'all_users' and ${sentCount} notification docs created`
        );
      }

      return {success: true, sentCount};
    } catch (error) {
      logger.error("Error sending promo notification", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to send promotional notification."
      );
    }
  }
);
