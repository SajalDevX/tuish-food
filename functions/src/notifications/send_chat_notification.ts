/**
 * Firestore trigger – fires when a new message is created in
 * chats/{chatId}/messages.
 *
 * Sends an FCM push notification to the other participant.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections, SubCollections, NotificationTypes} from "../utils/constants";
import {sendToUser, createNotificationDoc} from "./fcm_helpers";

const logger = functions.logger;

export const sendChatNotification = functions.firestore
  .document(
    `${Collections.CHATS}/{chatId}/${SubCollections.MESSAGES}/{messageId}`
  )
  .onCreate(async (snapshot, context) => {
    const {chatId} = context.params;
    const messageData = snapshot.data();

    const senderId = messageData.senderId as string;
    const text = (messageData.text as string) || "";
    const imageUrl = messageData.imageUrl as string | undefined;

    logger.info(`New chat message in ${chatId} from ${senderId}`);

    // Look up the chat document to find the other participant
    const db = admin.firestore();
    const chatDoc = await db
      .collection(Collections.CHATS)
      .doc(chatId)
      .get();

    if (!chatDoc.exists) {
      logger.warn(`Chat document ${chatId} not found`);
      return;
    }

    const chatData = chatDoc.data()!;
    const participants = chatData.participants as string[] | undefined;

    if (!participants || participants.length < 2) {
      logger.warn(`Chat ${chatId} has invalid participants`);
      return;
    }

    // Find the recipient (the participant who is NOT the sender)
    const recipientId = participants.find((p) => p !== senderId);
    if (!recipientId) {
      logger.warn(`Could not determine recipient in chat ${chatId}`);
      return;
    }

    // Get sender display name for the notification
    const senderDoc = await db
      .collection(Collections.USERS)
      .doc(senderId)
      .get();
    const senderName =
      (senderDoc.data()?.displayName as string) || "Someone";

    const title = `Message from ${senderName}`;
    const body = imageUrl ? "Sent an image" : text.substring(0, 100);
    const data: Record<string, string> = {
      chatId,
      senderId,
      type: NotificationTypes.CHAT,
    };

    try {
      await sendToUser(recipientId, title, body, data);
      await createNotificationDoc(
        recipientId,
        title,
        body,
        NotificationTypes.CHAT,
        data
      );
    } catch (error) {
      logger.error(`Failed to send chat notification for ${chatId}`, error);
    }
  });
