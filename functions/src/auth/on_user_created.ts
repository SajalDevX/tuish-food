/**
 * Auth trigger – runs when a new Firebase Auth user is created.
 * Creates a Firestore user document with default fields and sets
 * custom claims with role = 'customer'.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections, UserRoles} from "../utils/constants";

const logger = functions.logger;

export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  const {uid, email, phoneNumber, displayName, photoURL} = user;

  logger.info(`New user created: ${uid}`, {uid, email});

  const db = admin.firestore();
  const auth = admin.auth();
  const now = admin.firestore.FieldValue.serverTimestamp();

  try {
    // 1. Set custom claims (default role = customer)
    await auth.setCustomUserClaims(uid, {role: UserRoles.CUSTOMER});
    logger.info(`Custom claims set for user ${uid}`, {role: UserRoles.CUSTOMER});

    // 2. Create Firestore user document
    const userDoc: Record<string, unknown> = {
      email: email ?? null,
      phone: phoneNumber ?? null,
      displayName: displayName ?? null,
      photoUrl: photoURL ?? null,
      role: UserRoles.CUSTOMER,
      isActive: true,
      isBanned: false,
      fcmTokens: [],
      createdAt: now,
      updatedAt: now,
    };

    await db.collection(Collections.USERS).doc(uid).set(userDoc);
    logger.info(`Firestore user document created for ${uid}`);
  } catch (error) {
    logger.error(`Error in onUserCreated for ${uid}`, error);
    throw error;
  }
});
