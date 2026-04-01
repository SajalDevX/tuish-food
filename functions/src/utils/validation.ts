/**
 * Validation helpers for Tuish Food Cloud Functions.
 */

import {OrderStatuses} from "./constants";

// ── Email validation ────────────────────────────────────────────────────────

const EMAIL_REGEX =
  /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

/**
 * Returns `true` when the supplied string looks like a valid email address.
 */
export function validateEmail(email: string): boolean {
  if (!email || typeof email !== "string") return false;
  return EMAIL_REGEX.test(email.trim());
}

// ── Phone validation ────────────────────────────────────────────────────────

const PHONE_REGEX = /^\+?[1-9]\d{6,14}$/;

/**
 * Returns `true` when the supplied string is a valid E.164‑ish phone number.
 * Allows an optional leading '+' and 7–15 digits.
 */
export function validatePhone(phone: string): boolean {
  if (!phone || typeof phone !== "string") return false;
  return PHONE_REGEX.test(phone.trim().replace(/[\s()-]/g, ""));
}

// ── Order data validation ───────────────────────────────────────────────────

export interface OrderDataValidation {
  valid: boolean;
  errors: string[];
}

interface OrderItemInput {
  id?: unknown;
  name?: unknown;
  quantity?: unknown;
  price?: unknown;
  totalPrice?: unknown;
}

interface OrderInput {
  customerId?: unknown;
  restaurantId?: unknown;
  items?: unknown;
  subtotal?: unknown;
  deliveryFee?: unknown;
  serviceFee?: unknown;
  tax?: unknown;
  totalAmount?: unknown;
  paymentMethod?: unknown;
  deliveryAddress?: unknown;
  status?: unknown;
}

/**
 * Validates the core fields of an order document.
 * Returns an object with `valid` (boolean) and `errors` (string[]).
 */
export function validateOrderData(
  data: OrderInput | null | undefined
): OrderDataValidation {
  const errors: string[] = [];

  if (!data || typeof data !== "object") {
    return {valid: false, errors: ["Order data is missing or not an object."]};
  }

  // Required string fields
  if (!data.customerId || typeof data.customerId !== "string") {
    errors.push("customerId is required and must be a string.");
  }
  if (!data.restaurantId || typeof data.restaurantId !== "string") {
    errors.push("restaurantId is required and must be a string.");
  }
  if (!data.paymentMethod || typeof data.paymentMethod !== "string") {
    errors.push("paymentMethod is required and must be a string.");
  }
  if (!data.deliveryAddress || typeof data.deliveryAddress !== "string") {
    errors.push("deliveryAddress is required and must be a string.");
  }

  // Items array
  if (!Array.isArray(data.items) || data.items.length === 0) {
    errors.push("items must be a non‑empty array.");
  } else {
    (data.items as OrderItemInput[]).forEach((item, idx) => {
      if (!item.id || typeof item.id !== "string") {
        errors.push(`items[${idx}].id is required.`);
      }
      if (!item.name || typeof item.name !== "string") {
        errors.push(`items[${idx}].name is required.`);
      }
      if (typeof item.quantity !== "number" || item.quantity < 1) {
        errors.push(`items[${idx}].quantity must be a positive number.`);
      }
      if (typeof item.price !== "number" || item.price < 0) {
        errors.push(`items[${idx}].price must be a non‑negative number.`);
      }
    });
  }

  // Numeric amounts
  const numericFields: (keyof OrderInput)[] = [
    "subtotal",
    "deliveryFee",
    "serviceFee",
    "tax",
    "totalAmount",
  ];
  for (const field of numericFields) {
    const val = data[field];
    if (typeof val !== "number" || val < 0) {
      errors.push(`${field} must be a non‑negative number.`);
    }
  }

  // Status if present must be valid
  if (data.status !== undefined) {
    const validStatuses = Object.values(OrderStatuses) as string[];
    if (typeof data.status !== "string" || !validStatuses.includes(data.status)) {
      errors.push(`status must be one of: ${validStatuses.join(", ")}.`);
    }
  }

  return {valid: errors.length === 0, errors};
}
