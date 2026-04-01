/**
 * Callable function – validates a coupon code.
 *
 * Checks: exists, isActive, not expired, under usage limit, meets
 * minimum order amount.  Returns the discount amount.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections} from "../utils/constants";

const logger = functions.logger;

interface ValidateCouponInput {
  couponCode: string;
  subtotal: number;
}

interface CouponValidation {
  valid: boolean;
  discountAmount: number;
  discountType?: string;
  discountValue?: number;
  maxDiscount?: number;
  message: string;
  promotionId?: string;
}

export const validateCoupon = functions.https.onCall(
  async (data: ValidateCouponInput, context): Promise<CouponValidation> => {
    // ── Auth check ──────────────────────────────────────────────────────
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in."
      );
    }

    const {couponCode, subtotal} = data;

    if (!couponCode || typeof couponCode !== "string") {
      return {valid: false, discountAmount: 0, message: "Coupon code is required."};
    }
    if (typeof subtotal !== "number" || subtotal < 0) {
      return {valid: false, discountAmount: 0, message: "Valid subtotal is required."};
    }

    const db = admin.firestore();
    const code = couponCode.toUpperCase().trim();

    try {
      // Look up coupon by code
      const promoSnapshot = await db
        .collection(Collections.PROMOTIONS)
        .where("code", "==", code)
        .limit(1)
        .get();

      if (promoSnapshot.empty) {
        return {valid: false, discountAmount: 0, message: "Coupon code not found."};
      }

      const promoDoc = promoSnapshot.docs[0];
      const promo = promoDoc.data();

      // Check isActive
      if (!(promo.isActive as boolean)) {
        return {valid: false, discountAmount: 0, message: "This coupon is no longer active."};
      }

      // Check expiry
      const validUntil = promo.validUntil?.toDate?.() as Date | undefined;
      if (validUntil && new Date() > validUntil) {
        return {valid: false, discountAmount: 0, message: "This coupon has expired."};
      }

      // Check usage limit
      const maxUses = (promo.maxUses as number) || 0;
      const currentUses = (promo.currentUses as number) || 0;
      if (maxUses > 0 && currentUses >= maxUses) {
        return {
          valid: false,
          discountAmount: 0,
          message: "This coupon has reached its usage limit.",
        };
      }

      // Check per‑user usage limit
      const maxUsesPerUser = (promo.maxUsesPerUser as number) || 0;
      if (maxUsesPerUser > 0) {
        const userUsageSnapshot = await db
          .collection(Collections.ORDERS)
          .where("customerId", "==", context.auth.uid)
          .where("couponCode", "==", code)
          .where("status", "!=", "cancelled")
          .get();

        if (userUsageSnapshot.size >= maxUsesPerUser) {
          return {
            valid: false,
            discountAmount: 0,
            message: "You have already used this coupon the maximum number of times.",
          };
        }
      }

      // Check minimum order amount
      const minOrderAmount = (promo.minOrderAmount as number) || 0;
      if (subtotal < minOrderAmount) {
        return {
          valid: false,
          discountAmount: 0,
          message: `Minimum order amount of ₹${minOrderAmount} required for this coupon.`,
        };
      }

      // Calculate discount
      const discountType = (promo.discountType as string) || "flat";
      const discountValue = (promo.discountValue as number) || 0;
      const maxDiscount = (promo.maxDiscount as number) || Infinity;
      let discountAmount: number;

      if (discountType === "percentage") {
        discountAmount = Math.min((subtotal * discountValue) / 100, maxDiscount);
      } else {
        discountAmount = Math.min(discountValue, subtotal, maxDiscount);
      }

      discountAmount = Math.round(discountAmount * 100) / 100;

      logger.info(
        `Coupon ${code} validated: discount=₹${discountAmount} for subtotal=₹${subtotal}`
      );

      return {
        valid: true,
        discountAmount,
        discountType,
        discountValue,
        maxDiscount: maxDiscount === Infinity ? undefined : maxDiscount,
        message: `Coupon applied! You save ₹${discountAmount.toFixed(2)}.`,
        promotionId: promoDoc.id,
      };
    } catch (error) {
      logger.error("Error validating coupon", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to validate coupon."
      );
    }
  }
);
