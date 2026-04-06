/**
 * Callable function – lets a user select their own role during onboarding.
 *
 * Sets both Firebase custom claims and the Firestore user document.
 * Only allows non-admin roles. Only works if user has no role set yet
 * or is re-selecting (not overriding admin).
 *
 * Input:  { role: string }
 * Output: { success: true, role: string }
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections, UserRoles, UserRole} from "../utils/constants";

const logger = functions.logger;

interface SelectUserRoleData {
  role: string;
}

export const selectUserRole = functions.https.onCall(
  async (data: SelectUserRoleData, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in."
      );
    }

    const {role} = data;
    const allowedRoles: string[] = [
      UserRoles.CUSTOMER,
      UserRoles.DELIVERY_PARTNER,
      UserRoles.RESTAURANT_OWNER,
    ];

    if (!role || !allowedRoles.includes(role)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `role must be one of: ${allowedRoles.join(", ")}.`
      );
    }

    // Prevent admin escalation
    const currentRole = context.auth.token.role as string | undefined;
    if (currentRole === UserRoles.ADMIN) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Admins cannot change their role via this endpoint."
      );
    }

    const uid = context.auth.uid;
    const newRole = role as UserRole;

    try {
      const auth = admin.auth();
      const db = admin.firestore();

      // 1. Set custom claims
      await auth.setCustomUserClaims(uid, {role: newRole});

      // 2. Update Firestore user document
      await db.collection(Collections.USERS).doc(uid).update({
        role: newRole,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info(`User ${uid} selected role: ${newRole}`);

      return {success: true, role: newRole};
    } catch (error) {
      logger.error(`Error selecting role for ${uid}`, error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to set role. Please try again."
      );
    }
  }
);
