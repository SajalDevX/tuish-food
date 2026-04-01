/**
 * Callable function – calculates the full fee breakdown for an order.
 *
 * Input:  { subtotal, deliveryDistanceKm, couponCode? }
 * Output: { deliveryFee, serviceFee, tax, discount, total }
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Collections, Fees} from "../utils/constants";

const logger = functions.logger;

interface CalculateFeesInput {
  subtotal: number;
  deliveryDistanceKm: number;
  couponCode?: string;
}

interface FeeBreakdown {
  subtotal: number;
  deliveryFee: number;
  serviceFee: number;
  tax: number;
  discount: number;
  total: number;
}

export const calculateFees = functions.https.onCall(
  async (data: CalculateFeesInput, context): Promise<FeeBreakdown> => {
    // ── Auth check ──────────────────────────────────────────────────────
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in."
      );
    }

    // ── Validate input ──────────────────────────────────────────────────
    const {subtotal, deliveryDistanceKm, couponCode} = data;

    if (typeof subtotal !== "number" || subtotal < 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "subtotal must be a non‑negative number."
      );
    }
    if (typeof deliveryDistanceKm !== "number" || deliveryDistanceKm < 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "deliveryDistanceKm must be a non‑negative number."
      );
    }

    // ── Calculate delivery fee ──────────────────────────────────────────
    let deliveryFee = Fees.DEFAULT_DELIVERY_FEE;
    if (deliveryDistanceKm > Fees.BASE_DELIVERY_DISTANCE_KM) {
      const extraKm = deliveryDistanceKm - Fees.BASE_DELIVERY_DISTANCE_KM;
      deliveryFee += Math.ceil(extraKm) * Fees.PER_KM_SURCHARGE;
    }

    // ── Service fee ─────────────────────────────────────────────────────
    const serviceFee = Math.round(subtotal * Fees.SERVICE_FEE_PERCENTAGE * 100) / 100;

    // ── Tax ─────────────────────────────────────────────────────────────
    const tax = Math.round(subtotal * Fees.TAX_PERCENTAGE * 100) / 100;

    // ── Discount (optional coupon) ──────────────────────────────────────
    let discount = 0;

    if (couponCode && typeof couponCode === "string") {
      try {
        const promoSnapshot = await admin
          .firestore()
          .collection(Collections.PROMOTIONS)
          .where("code", "==", couponCode.toUpperCase())
          .where("isActive", "==", true)
          .limit(1)
          .get();

        if (!promoSnapshot.empty) {
          const promo = promoSnapshot.docs[0].data();
          const now = new Date();
          const validUntil = promo.validUntil?.toDate?.() as Date | undefined;
          const minOrderAmount = (promo.minOrderAmount as number) || 0;
          const maxUses = (promo.maxUses as number) || Infinity;
          const currentUses = (promo.currentUses as number) || 0;

          if (
            (!validUntil || now <= validUntil) &&
            subtotal >= minOrderAmount &&
            currentUses < maxUses
          ) {
            const discountType = promo.discountType as string;
            const discountValue = (promo.discountValue as number) || 0;
            const maxDiscount = (promo.maxDiscount as number) || Infinity;

            if (discountType === "percentage") {
              discount = Math.min(
                (subtotal * discountValue) / 100,
                maxDiscount
              );
            } else {
              // flat
              discount = Math.min(discountValue, subtotal, maxDiscount);
            }

            discount = Math.round(discount * 100) / 100;
          }
        }
      } catch (error) {
        logger.error("Error validating coupon in calculateFees", error);
        // Non-fatal: just proceed without discount
      }
    }

    // ── Total ───────────────────────────────────────────────────────────
    const total =
      Math.round((subtotal + deliveryFee + serviceFee + tax - discount) * 100) /
      100;

    return {
      subtotal,
      deliveryFee,
      serviceFee,
      tax,
      discount,
      total: Math.max(total, 0),
    };
  }
);
