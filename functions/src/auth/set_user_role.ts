/**
 * Callable function – allows an admin to change a user's role.
 * Verifies the caller has the 'admin' custom claim, then updates
 * both the Auth custom claims and the Firestore user document.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections, UserRoles, UserRole} from "../utils/constants";

const logger = functions.logger;

interface SetUserRoleData {
  targetUid: string;
  role: string;
}

export const setUserRole = functions.https.onCall(
  async (data: SetUserRoleData, context) => {
    // ── Auth check ────────────────────────────────────────────────────────
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in to call this function."
      );
    }

    const callerRole = context.auth.token.role as string | undefined;
    if (callerRole !== UserRoles.ADMIN) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can change user roles."
      );
    }

    // ── Input validation ──────────────────────────────────────────────────
    const {targetUid, role} = data;
    if (!targetUid || typeof targetUid !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "targetUid is required."
      );
    }

    const validRoles: string[] = Object.values(UserRoles);
    if (!role || !validRoles.includes(role)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `role must be one of: ${validRoles.join(", ")}.`
      );
    }

    const newRole = role as UserRole;

    try {
      const auth = admin.auth();
      const db = admin.firestore();

      // Verify the target user exists
      await auth.getUser(targetUid);

      // Update custom claims
      await auth.setCustomUserClaims(targetUid, {role: newRole});
      logger.info(`Custom claims updated for ${targetUid}`, {role: newRole});

      // Update Firestore user doc
      await db.collection(Collections.USERS).doc(targetUid).update({
        role: newRole,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info(`Role updated for user ${targetUid} to ${newRole}`);

      return {success: true, uid: targetUid, role: newRole};
    } catch (error) {
      logger.error(`Error setting role for ${targetUid}`, error);
      if (
        error instanceof Error &&
        "code" in error &&
        (error as {code: string}).code === "auth/user-not-found"
      ) {
        throw new functions.https.HttpsError(
          "not-found",
          `User ${targetUid} not found.`
        );
      }
      throw new functions.https.HttpsError(
        "internal",
        "Failed to set user role."
      );
    }
  }
);
