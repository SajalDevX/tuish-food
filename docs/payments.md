# Payments

This document describes the payment processing architecture for Tuish Food, including Stripe integration, checkout flow, refund handling, tip management, and fee calculations.

---

## Payment Architecture

```
+-------------------+     +-------------------+     +-------------------+
|    Flutter App     |     | Cloud Functions   |     |      Stripe       |
|  (flutter_stripe)  |     | (Server-side)     |     |    (Payments)     |
+-------------------+     +-------------------+     +-------------------+
        |                         |                         |
        | 1. Request checkout     |                         |
        +------------------------>|                         |
        |                         | 2. Create PaymentIntent |
        |                         +------------------------>|
        |                         |                         |
        |                         | 3. Return client_secret |
        |                         |<------------------------+
        | 4. client_secret        |                         |
        |<------------------------+                         |
        |                                                   |
        | 5. Confirm payment                                |
        |   (flutter_stripe SDK)                            |
        +-------------------------------------------------->|
        |                                                   |
        | 6. Payment result                                 |
        |<--------------------------------------------------+
        |                         |                         |
        |                         | 7. Webhook: payment     |
        |                         |    succeeded            |
        |                         |<------------------------+
        |                         |                         |
        | 8. Order confirmed      | 8. Update order status  |
        |<------------------------+                         |
```

---

## Supported Payment Methods

| Method | Integration | Availability |
| ------ | ----------- | ------------ |
| **Credit/Debit Card** | Stripe (flutter_stripe) | All orders |
| **Cash on Delivery** | No payment processing | All orders |
| **Wallet/Credits** | Custom implementation | Future enhancement |

---

## Stripe Setup

### Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter_stripe: ^10.0.0
```

### Initialization

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Stripe.publishableKey = const String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_...',
  );

  // Optional: Set merchant identifier for Apple Pay
  Stripe.merchantIdentifier = 'merchant.com.tuishfood';

  await Stripe.instance.applySettings();

  runApp(const ProviderScope(child: TuishFoodApp()));
}
```

### Server-Side (Cloud Functions)

```typescript
// functions/src/payments.ts
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2024-12-18.acacia',
});
```

---

## Checkout Flow

### Step-by-Step Flow

```
Customer taps "Place Order"
    |
    v
1. Client validates:
   - Delivery address selected
   - Payment method selected
   - Cart not empty
   - Above minimum order
    |
    v
2. Client calls calculateFees Cloud Function
   (server-side validation and price calculation)
    |
    v
3. Server returns verified PriceBreakdown
    |
    v
4. Payment method check:
    |
    +-- Cash on Delivery
    |     |
    |     v
    |   Create order document in Firestore
    |     paymentStatus: 'pending'
    |     paymentMethod: 'cash'
    |     |
    |     v
    |   Navigate to order confirmation
    |
    +-- Card Payment
          |
          v
        5. Client calls createPaymentIntent Cloud Function
          |
          v
        6. Server creates Stripe PaymentIntent:
           - amount: total (cents)
           - currency: 'usd'
           - customer: stripeCustomerId
           - metadata: { orderId, customerId, restaurantId }
          |
          v
        7. Server returns clientSecret
          |
          v
        8. Client calls Stripe.instance.confirmPayment(clientSecret)
           - Shows Stripe payment sheet
           - User enters/confirms card details
          |
          v
        9. Payment result:
          |
          +-- Success
          |     |
          |     v
          |   Create order document in Firestore
          |     paymentStatus: 'paid'
          |     paymentMethod: 'card'
          |     stripePaymentIntentId: 'pi_xxx'
          |     |
          |     v
          |   Navigate to order confirmation
          |
          +-- Failure
                |
                v
              Show error message
              "Payment failed. Please try again."
              [Retry] [Change Payment Method]
```

### Create PaymentIntent Cloud Function

```typescript
exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const { restaurantId, items, deliveryAddress, couponCode, tip } = data;

  // 1. Recalculate fees server-side (prevent tampering)
  const pricing = await calculatePricing({
    restaurantId,
    items,
    deliveryAddress,
    couponCode,
    tip: tip || 0,
  });

  // 2. Get or create Stripe customer
  const userDoc = await admin.firestore().doc(`users/${context.auth.uid}`).get();
  let stripeCustomerId = userDoc.data()?.stripeCustomerId;

  if (!stripeCustomerId) {
    const customer = await stripe.customers.create({
      email: userDoc.data()?.email,
      name: userDoc.data()?.displayName,
      metadata: { firebaseUid: context.auth.uid },
    });
    stripeCustomerId = customer.id;

    await admin.firestore().doc(`users/${context.auth.uid}`).update({
      stripeCustomerId: customer.id,
    });
  }

  // 3. Create PaymentIntent
  const paymentIntent = await stripe.paymentIntents.create({
    amount: pricing.total, // Already in cents
    currency: 'usd',
    customer: stripeCustomerId,
    automatic_payment_methods: { enabled: true },
    metadata: {
      customerId: context.auth.uid,
      restaurantId: restaurantId,
      itemCount: items.length.toString(),
      subtotal: pricing.subtotal.toString(),
      deliveryFee: pricing.deliveryFee.toString(),
      serviceFee: pricing.serviceFee.toString(),
      tax: pricing.tax.toString(),
      tip: pricing.tip.toString(),
      discount: pricing.discount.toString(),
    },
  });

  // 4. Return client secret
  return {
    clientSecret: paymentIntent.client_secret,
    paymentIntentId: paymentIntent.id,
    pricing: pricing,
  };
});
```

---

## Webhook Handling

Stripe webhooks provide server-side confirmation of payment events, serving as the source of truth for payment status.

### Webhook Endpoint

```typescript
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'] as string;
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET!;

  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err);
    res.status(400).send('Webhook Error');
    return;
  }

  switch (event.type) {
    case 'payment_intent.succeeded': {
      const paymentIntent = event.data.object as Stripe.PaymentIntent;
      await handlePaymentSuccess(paymentIntent);
      break;
    }

    case 'payment_intent.payment_failed': {
      const paymentIntent = event.data.object as Stripe.PaymentIntent;
      await handlePaymentFailure(paymentIntent);
      break;
    }

    case 'charge.refunded': {
      const charge = event.data.object as Stripe.Charge;
      await handleRefund(charge);
      break;
    }

    default:
      console.log(`Unhandled event type: ${event.type}`);
  }

  res.json({ received: true });
});

async function handlePaymentSuccess(paymentIntent: Stripe.PaymentIntent) {
  const { customerId } = paymentIntent.metadata;

  // Find order by paymentIntentId and update status
  const ordersSnapshot = await admin.firestore()
    .collection('orders')
    .where('stripePaymentIntentId', '==', paymentIntent.id)
    .limit(1)
    .get();

  if (!ordersSnapshot.empty) {
    await ordersSnapshot.docs[0].ref.update({
      paymentStatus: 'paid',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

async function handlePaymentFailure(paymentIntent: Stripe.PaymentIntent) {
  const ordersSnapshot = await admin.firestore()
    .collection('orders')
    .where('stripePaymentIntentId', '==', paymentIntent.id)
    .limit(1)
    .get();

  if (!ordersSnapshot.empty) {
    await ordersSnapshot.docs[0].ref.update({
      paymentStatus: 'failed',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}
```

---

## Refund Flow

### Admin-Initiated Refund

```
Admin opens order detail
    |
    v
Taps "Process Refund"
    |
    v
Select refund type:
    |
    +-- Full Refund
    |     amount = order.pricing.total
    |
    +-- Partial Refund
          Enter amount (must be <= total)
    |
    v
Enter refund reason
    |
    v
Confirm refund
    |
    v
Cloud Function: processRefund
    |
    v
Stripe API: stripe.refunds.create({
  payment_intent: order.stripePaymentIntentId,
  amount: refundAmount, // cents
  reason: 'requested_by_customer',
})
    |
    v
Update order:
  paymentStatus: 'refunded'
  refundAmount: amount
  refundReason: reason
  refundedAt: timestamp
    |
    v
Send notification to customer:
  "Your refund of $X.XX has been processed"
```

### Auto-Refund on Cancellation

When an order with card payment is cancelled:

```typescript
async function handleOrderCancellation(orderId: string) {
  const order = await admin.firestore().doc(`orders/${orderId}`).get();
  const data = order.data()!;

  if (data.paymentMethod === 'card' && data.paymentStatus === 'paid') {
    // Full refund
    await stripe.refunds.create({
      payment_intent: data.stripePaymentIntentId,
    });

    await order.ref.update({
      paymentStatus: 'refunded',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}
```

### Refund Timeline

| Payment Method | Refund Method | Customer Timeline |
| -------------- | ------------- | ----------------- |
| Card | Stripe refund | 5-10 business days (bank dependent) |
| Cash | No refund needed | Immediate (order not yet paid) |

---

## Tip Handling

Tips are added to the order total and routed entirely to the delivery partner.

### Checkout UI

```
Tip for Delivery Partner:
  [ No Tip ]  [ $2 ]  [ $5 ]  [ $8 ]  [ Custom ]
```

### Tip Flow

```
1. Customer selects tip amount during checkout
     |
     v
2. Tip included in PaymentIntent total:
   total = subtotal + deliveryFee + serviceFee + tax + tip - discount
     |
     v
3. Tip stored in order document:
   pricing.tip = tipAmount (cents)
     |
     v
4. On delivery completion, Cloud Function creates earnings record:
   {
     deliveryFee: order.pricing.deliveryFee,
     tip: order.pricing.tip,
     totalEarning: deliveryFee + tip,
   }
     |
     v
5. Tip included in partner's weekly payout
```

### Post-Delivery Tip (Future Enhancement)

Allow customers to add or increase tip after delivery is completed, within a 24-hour window.

---

## Fee Breakdown

Every order has a detailed price breakdown stored in the `pricing` map:

### Calculation Formula

```
subtotal        = SUM(item.totalPrice for each item in cart)
deliveryFee     = max(defaultDeliveryFee, defaultDeliveryFee + (distance * deliveryFeePerKm))
serviceFee      = clamp(subtotal * serviceFeePercentage, serviceFeeMin, serviceFeeMax)
tax             = subtotal * taxPercentage
tip             = customerSelectedTip
discount        = calculateDiscount(coupon, subtotal)
--------------------------------------------------------------
total           = subtotal + deliveryFee + serviceFee + tax + tip - discount
```

### Server-Side Calculation (Source of Truth)

```typescript
interface PricingInput {
  restaurantId: string;
  items: Array<{
    itemId: string;
    quantity: number;
    customizations: Array<{
      groupId: string;
      selectedOptionIds: string[];
    }>;
  }>;
  deliveryAddress: { location: GeoPoint };
  couponCode?: string;
  tip: number;
}

async function calculatePricing(input: PricingInput): Promise<PriceBreakdown> {
  // 1. Fetch app config
  const config = await admin.firestore().doc('app_config/settings').get();
  const settings = config.data()!;

  // 2. Fetch restaurant
  const restaurant = await admin.firestore()
    .doc(`restaurants/${input.restaurantId}`)
    .get();
  const restData = restaurant.data()!;

  // 3. Calculate subtotal from actual menu item prices
  let subtotal = 0;
  for (const item of input.items) {
    const menuItem = await admin.firestore()
      .doc(`restaurants/${input.restaurantId}/menuItems/${item.itemId}`)
      .get();
    const menuData = menuItem.data()!;

    let itemPrice = menuData.discountedPrice ?? menuData.price;

    // Add customization price adjustments
    for (const customization of item.customizations) {
      const group = menuData.customizations.find(
        (c: any) => c.id === customization.groupId
      );
      if (group) {
        for (const optionId of customization.selectedOptionIds) {
          const option = group.options.find((o: any) => o.id === optionId);
          if (option) {
            itemPrice += option.priceAdjustment;
          }
        }
      }
    }

    subtotal += itemPrice * item.quantity;
  }

  // 4. Calculate delivery fee
  const distance = haversineDistance(
    restData.location,
    input.deliveryAddress.location
  );
  const deliveryFee = Math.max(
    restData.deliveryFee || settings.defaultDeliveryFee,
    settings.defaultDeliveryFee + Math.round(distance * settings.deliveryFeePerKm)
  );

  // 5. Calculate service fee
  const rawServiceFee = Math.round(subtotal * settings.serviceFeePercentage / 100);
  const serviceFee = Math.max(
    settings.serviceFeeMin,
    Math.min(settings.serviceFeeMax, rawServiceFee)
  );

  // 6. Calculate tax
  const tax = Math.round(subtotal * settings.taxPercentage / 100);

  // 7. Calculate discount
  let discount = 0;
  if (input.couponCode) {
    discount = await calculateCouponDiscount(
      input.couponCode,
      subtotal,
      input.restaurantId
    );
  }

  // 8. Calculate total
  const total = subtotal + deliveryFee + serviceFee + tax + input.tip - discount;

  return {
    subtotal,
    deliveryFee,
    serviceFee,
    tax,
    tip: input.tip,
    discount,
    total: Math.max(0, total),
  };
}
```

### Example Breakdown

```
Order: 2x Margherita Pizza (Large) + 1x Caesar Salad

Item 1: Margherita Pizza
  Base price:         $12.99
  Size (Large):       +$4.00
  Quantity:           x2
  Item total:         $33.98

Item 2: Caesar Salad
  Base price:         $8.99
  Quantity:           x1
  Item total:         $8.99

Subtotal:             $42.97
Delivery Fee:         $4.99  (base $2.99 + 2.3km * $0.87/km)
Service Fee:          $2.15  (5% of $42.97, within min/max)
Tax:                  $3.54  (8.25% of $42.97)
Tip:                  $5.00  (customer selected)
Discount:            -$0.00  (no coupon)
---------------------------------------
Total:               $58.65
```

---

## Saved Payment Methods

### Saving Cards

When a customer pays for the first time, their card is saved to their Stripe customer for future use:

```dart
// Using Stripe's SetupIntent for saving cards
Future<void> savePaymentMethod() async {
  final callable = FirebaseFunctions.instance
      .httpsCallable('createSetupIntent');
  final result = await callable.call();

  await Stripe.instance.confirmSetupIntent(
    paymentIntentClientSecret: result.data['clientSecret'],
    params: const PaymentMethodParams.card(
      paymentMethodData: PaymentMethodData(),
    ),
  );
}
```

### Listing Saved Cards

```typescript
exports.getPaymentMethods = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', '');

  const userDoc = await admin.firestore().doc(`users/${context.auth.uid}`).get();
  const stripeCustomerId = userDoc.data()?.stripeCustomerId;

  if (!stripeCustomerId) return { paymentMethods: [] };

  const methods = await stripe.paymentMethods.list({
    customer: stripeCustomerId,
    type: 'card',
  });

  return {
    paymentMethods: methods.data.map(m => ({
      id: m.id,
      brand: m.card?.brand,
      last4: m.card?.last4,
      expiryMonth: m.card?.exp_month,
      expiryYear: m.card?.exp_year,
    })),
  };
});
```

---

## Security Considerations

| Concern | Mitigation |
| ------- | ---------- |
| Price tampering | All prices recalculated server-side before creating PaymentIntent |
| Replay attacks | PaymentIntent ID is unique and one-time use |
| Card data | Never touches our servers; handled entirely by Stripe SDK |
| Webhook authenticity | Stripe signature verification on all webhook events |
| PCI compliance | Using Stripe Elements/SDK ensures PCI-DSS compliance (SAQ A) |
| Refund abuse | Refunds require admin role; tracked with reasons and audit log |

---

## Future: Wallet / Credits System

Planned for a future release:

- **Wallet balance**: Users can top up a wallet and pay from balance.
- **Referral credits**: Earned through referral program.
- **Refund credits**: Option to refund to wallet (instant) instead of card (5-10 days).
- **Payment priority**: Wallet balance applied first, remaining charged to card.
- **Wallet transactions**: Full transaction history with deposits, payments, refunds, credits.
