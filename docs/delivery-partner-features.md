# Delivery Partner Features

This document describes all delivery partner features in the Tuish Food app, including the registration/verification process, active delivery workflow, earnings tracking, and screen flows.

---

## Screen Flow Overview

```
Login / Signup
    |
    v
Check verificationStatus
    |
    +-- null (new user) --> Partner Registration Screen
    |                             |
    |                             v
    |                       Verification Pending Screen
    |
    +-- 'pending' --> Verification Pending Screen
    |
    +-- 'rejected' --> Resubmit Documents Screen
    |
    +-- 'approved' --> Delivery Shell (Bottom Navigation)
                          |
                          +-- Home Tab
                          |     |-- Dashboard (online/offline toggle)
                          |     |-- Incoming Order Card
                          |     |-- Active Delivery Screen
                          |     |     |-- Navigation Screen (Google Maps)
                          |     |     |-- Order Detail Screen
                          |     |     |-- Chat Screen
                          |
                          +-- Orders Tab
                          |     |-- Delivery History
                          |     |-- Delivery Detail
                          |
                          +-- Earnings Tab
                          |     |-- Earnings Overview
                          |     |-- Daily/Weekly/Monthly Breakdown
                          |     |-- Payout History
                          |
                          +-- Profile Tab
                                |-- Profile Screen
                                |-- Vehicle Info
                                |-- Documents
                                |-- Rating History
                                |-- Settings
```

---

## 1. Registration and Verification

### Partner Registration Screen

After a user signs up (initially as a customer), they can apply to become a delivery partner from their profile or a dedicated "Become a Partner" section.

**Registration Form:**

1. **Personal Information** (pre-filled from profile):
   - Full name
   - Phone number (verified)
   - Profile photo

2. **Vehicle Information**:
   - Vehicle type selector: Bicycle, Motorcycle, Car
   - License plate number (required for motorcycle/car)

3. **Document Upload**:
   - Driver's license photo (front) -- required
   - Government ID photo (front + back) -- required
   - Vehicle registration document (required for motorcycle/car)
   - Each upload shows preview, allows retake/reselect

4. **Agreements**:
   - Accept Terms of Service for delivery partners
   - Accept background check consent
   - Accept delivery guidelines

5. **Submit Application** button

### Upload Flow

```
Select Image (camera or gallery)
    |
    v
Compress image (max 1024px width, 80% quality)
    |
    v
Upload to Firebase Storage
    path: users/{uid}/documents/{documentType}_{timestamp}.jpg
    |
    v
Store download URL in user document
    |
    v
Show upload success with preview
```

### Verification Pending Screen

Shown while the admin reviews the application.

- Status indicator: "Application Under Review"
- Estimated review time: "Usually within 24-48 hours"
- Document status list showing each document as uploaded/reviewing
- "Contact Support" button
- Pull-to-refresh to check status
- Push notification sent when status changes

### Admin Rejection Flow

If rejected, the partner sees:

- Rejection reason provided by admin
- Which documents need to be resubmitted
- "Resubmit" button to upload corrected documents
- Status changes back to `pending` after resubmission

---

## 2. Dashboard (Home Screen)

The delivery partner's primary screen when they open the app.

### Online/Offline Toggle

A prominent switch at the top of the screen:

```
+------------------------------------------+
|  [Profile Photo]  John D.                |
|                                          |
|  +------------------------------------+  |
|  |  O F F L I N E  [=====> ]  ONLINE  |  |
|  +------------------------------------+  |
|                                          |
|  Today's Stats:                          |
|  Deliveries: 5  |  Earned: $78.50       |
|  Online: 3h 22m |  Rating: 4.8          |
+------------------------------------------+
```

**Going Online:**
1. Check location permission (request if not granted).
2. Start background location service.
3. Update `users/{uid}.isOnline = true`.
4. Create/update `delivery_locations/{uid}` document.
5. Begin listening for incoming orders.

**Going Offline:**
1. Stop location updates.
2. Update `users/{uid}.isOnline = false`.
3. Update `delivery_locations/{uid}.isOnline = false`.
4. If active delivery exists, show warning: "You have an active delivery. Complete it before going offline."

### Dashboard Stats

- **Today's deliveries**: Count of completed deliveries today.
- **Today's earnings**: Sum of today's earnings.
- **Time online**: Duration since going online (or total for today).
- **Current rating**: Average rating.

### Background Location Tracking

When online, the app tracks GPS in the background:

| Platform | Method |
| -------- | ------ |
| Android | Foreground service with persistent notification ("Tuish Food - You're online") |
| iOS | Background location mode + significant change monitoring |

Location updates are sent to `delivery_locations/{uid}` every 5 seconds during active delivery, every 15 seconds when online but idle.

---

## 3. Incoming Order (Available Orders)

When a new order needs a delivery partner, nearby online partners receive a notification and an in-app order card.

### Incoming Order Card

Slides up from the bottom of the screen with a countdown timer:

```
+------------------------------------------+
|  NEW DELIVERY REQUEST         00:30      |
|                                          |
|  Restaurant: Pizza Palace                |
|  Pickup: 1.2 km away                    |
|  Delivery: 3.4 km from restaurant        |
|                                          |
|  Items: 3 items                          |
|  Estimated earnings: $8.50               |
|                                          |
|  +----------------+  +----------------+  |
|  |    DECLINE     |  |    ACCEPT      |  |
|  +----------------+  +----------------+  |
+------------------------------------------+
```

### Countdown Timer

- **30-second window** to accept or decline.
- Visual countdown (circular progress indicator + seconds).
- If timer expires: treated as decline, order offered to next nearest partner.
- Sound and vibration alert when order appears.

### Accept Flow

```
Partner taps "Accept"
    |
    v
Cloud Function: assignDeliveryPartner
    |  - Sets order.deliveryPartnerId = partnerId
    |  - Sets order.status = 'readyForPickup' (if restaurant ready)
    |  - Sets user.currentOrderId = orderId
    |  - Sends notification to customer ("Partner assigned")
    v
Navigate to Active Delivery Screen
    |  - Show pickup navigation
```

### Decline Flow

```
Partner taps "Decline" or timer expires
    |
    v
Order removed from partner's screen
    |
    v
System offers to next nearest available partner
```

---

## 4. Active Delivery Screen

The primary screen during an active delivery. Two phases: pickup and drop-off.

### Phase 1: Pickup (Navigate to Restaurant)

```
+------------------------------------------+
|  [Map showing route to restaurant]       |
|                                          |
|  Restaurant: Pizza Palace                |
|  Address: 123 Main St                    |
|  Distance: 1.2 km  |  ETA: 5 min        |
|                                          |
|  Order #TF-20260328-A1B2                 |
|  Items: 3 items                          |
|                                          |
|  [Call Restaurant]  [View Order Details] |
|                                          |
|  +------------------------------------+  |
|  |       ARRIVED AT RESTAURANT        |  |
|  +------------------------------------+  |
+------------------------------------------+
```

**Actions:**
- **Navigate**: Opens Google Maps or in-app navigation.
- **Call Restaurant**: Opens phone dialer.
- **View Order Details**: Expands to show all items and special instructions.
- **Arrived at Restaurant**: Confirms arrival, changes display to pickup confirmation.

### Phase 1b: At Restaurant (Waiting for Pickup)

```
+------------------------------------------+
|  Waiting for order...                    |
|                                          |
|  Order #TF-20260328-A1B2                 |
|                                          |
|  Items:                                  |
|  [x] 2x Margherita Pizza (Large)        |
|  [x] 1x Caesar Salad                    |
|                                          |
|  Special Instructions:                   |
|  "Extra napkins please"                  |
|                                          |
|  +------------------------------------+  |
|  |        PICKED UP ORDER             |  |
|  +------------------------------------+  |
+------------------------------------------+
```

**"Picked Up Order" button:**
- Updates order status to `pickedUp`.
- Sends notification to customer.
- Switches to Phase 2 (drop-off navigation).
- Optional: confirmation code from restaurant (future feature).

### Phase 2: Drop-off (Navigate to Customer)

```
+------------------------------------------+
|  [Map showing route to customer]         |
|                                          |
|  Customer: Jane S.                       |
|  Address: 456 Oak Ave, Apt 2B           |
|  Instructions: "Ring doorbell twice"     |
|  Distance: 3.4 km  |  ETA: 12 min       |
|                                          |
|  [Call Customer]  [Chat]  [Order Detail] |
|                                          |
|  +------------------------------------+  |
|  |       ARRIVED AT DESTINATION       |  |
|  +------------------------------------+  |
+------------------------------------------+
```

### Phase 2b: At Customer Location

```
+------------------------------------------+
|  Deliver order to customer               |
|                                          |
|  Customer: Jane S.                       |
|  Apt 2B - "Ring doorbell twice"          |
|                                          |
|  Payment: Card (Already paid)            |
|  -- or --                                |
|  Payment: Cash - Collect $49.02          |
|                                          |
|  +------------------------------------+  |
|  |       DELIVERY COMPLETED           |  |
|  +------------------------------------+  |
+------------------------------------------+
```

**"Delivery Completed" button:**
- Updates order status to `delivered`.
- Sets `actualDeliveryTime`.
- Sends notification to customer.
- Triggers `onDeliveryCompleted` Cloud Function (creates earnings record).
- Clears `currentOrderId` from partner document.
- Shows delivery summary with earnings.
- Returns to dashboard.

---

## 5. Navigation Screen

Full-screen Google Maps navigation during delivery.

### Features

- **Route polyline**: Drawn from current location to destination (restaurant or customer).
- **Custom markers**:
  - Partner location: Vehicle icon (bicycle/motorcycle/car) pointing in direction of travel.
  - Destination: Restaurant icon (pickup) or pin icon (drop-off).
- **Turn-by-turn directions**: List of steps from Google Directions API shown in a draggable bottom sheet.
- **Re-route**: Recalculates route if partner deviates significantly.
- **ETA**: Continuously updated based on current location and traffic.
- **Open in external maps**: Button to open Google Maps / Apple Maps for full navigation experience.

### Implementation

```dart
// Fetch route from Google Directions API
final directions = await directionsService.getRoute(
  origin: currentLocation,
  destination: destinationLocation,
  mode: TravelMode.driving, // or bicycling
);

// Draw polyline on map
final polyline = Polyline(
  polylineId: const PolylineId('route'),
  points: directions.polylinePoints,
  color: AppColors.primary,
  width: 5,
);

// Update ETA
final eta = directions.duration;
```

---

## 6. Order Detail Screen

Accessible during active delivery or from delivery history.

### Information Shown

- **Order number** and timestamp
- **Restaurant info**: Name, address, phone
- **Customer info**: Name, address, phone, delivery instructions
- **Items list**:
  - Item name, quantity, customizations
  - Special instructions per item
- **Payment method**: Card (paid) or Cash (collect amount)
- **Pricing**: Delivery fee and tip earned
- **Status history**: Timeline of all status changes

---

## 7. Chat with Customer

In-app messaging between delivery partner and customer during active order.

### Chat Screen

- Standard messaging UI with bubbles (partner on right, customer on left).
- **Text messages**: Free-form text input.
- **Image messages**: Camera/gallery to send photos (e.g., "I'm at the blue door").
- **System messages**: Automated messages like "Delivery partner is 2 minutes away".
- **Quick replies**: Pre-written messages for common situations:
  - "I'm at the restaurant, picking up your order."
  - "Your order is on the way!"
  - "I've arrived at your location."
  - "I'm having trouble finding your location. Can you help?"
- Chat is **disabled** after delivery is completed (read-only).

---

## 8. Earnings

### Earnings Overview Screen

```
+------------------------------------------+
|  EARNINGS                                |
|                                          |
|  [Daily]  [Weekly]  [Monthly]            |
|                                          |
|  This Week: $342.50                      |
|  +------------------------------------+  |
|  |  [Bar chart - daily breakdown]     |  |
|  +------------------------------------+  |
|                                          |
|  Breakdown:                              |
|  Delivery Fees:    $245.00               |
|  Tips:             $87.50                |
|  Bonuses:          $10.00                |
|  ---------------------------------       |
|  Total:            $342.50               |
|                                          |
|  Deliveries: 42  |  Avg: $8.15/delivery |
+------------------------------------------+
```

### Time Period Views

| View | Display | Chart |
| ---- | ------- | ----- |
| **Daily** | Hourly earnings for today | Bar chart (hours) |
| **Weekly** | Daily earnings for current week | Bar chart (Mon-Sun) |
| **Monthly** | Weekly earnings for current month | Bar chart (Week 1-4) |

### Charts (fl_chart)

- Bar charts showing earnings per period.
- Color-coded: Blue for delivery fees, Green for tips, Gold for bonuses.
- Tap on a bar to see breakdown for that period.

### Payout History

```
+------------------------------------------+
|  PAYOUT HISTORY                          |
|                                          |
|  Mar 24, 2026       $342.50    Paid      |
|  Mar 17, 2026       $298.00    Paid      |
|  Mar 10, 2026       $415.75    Paid      |
|  Mar 03, 2026       $267.25    Paid      |
+------------------------------------------+
```

- Weekly payouts processed every Monday (configurable in `app_config`).
- Each payout shows: date, amount, status (pending/processing/paid).
- Tap for payout detail showing all deliveries included.

---

## 9. Profile

### Profile Screen

- **Profile photo and name**
- **Rating**: Large star display with total number of ratings
- **Stats**: Total deliveries, months active, acceptance rate
- **Menu items**:
  - Vehicle Information (edit vehicle type, plate number)
  - My Documents (view uploaded documents, status)
  - Rating History (see individual ratings and comments)
  - Notification Settings
  - Help & Support
  - Terms of Service
  - Sign Out

### Vehicle Information

- Vehicle type (changeable, may require re-verification)
- License plate number
- Vehicle photo (optional)

### Documents

- View status of each uploaded document
- Re-upload if expired or if prompted by admin
- Document types: Driver's license, Government ID, Vehicle registration

### Rating History

- List of all ratings received from customers
- Each entry shows: date, rating stars, comment (if any), order number
- Overall rating trend chart (last 30 days)
- Tips for improving rating

---

## Status Update Permissions

The delivery partner can only update order status in specific ways:

| Current Status | Partner Can Set | Action |
| -------------- | --------------- | ------ |
| `readyForPickup` | (no change, just navigate to restaurant) | -- |
| `readyForPickup` | `pickedUp` | "Picked Up Order" button |
| `pickedUp` | `delivered` | "Delivery Completed" button |

All other status transitions are handled by the restaurant (confirm, prepare) or system (cancel).

---

## Offline Behavior

| Scenario | Behavior |
| -------- | -------- |
| App killed while online | Background service continues; FCM still delivers notifications |
| Internet lost during delivery | Location updates queued locally, synced when reconnected |
| App reopened after force close | If `currentOrderId` exists, resume active delivery screen |
| Phone restart | Background service restarts (Android: `START_STICKY`; iOS: significant location change) |
