# Admin Features

This document describes all admin panel features in the Tuish Food app. The admin panel is accessible via the mobile app (for admins with the `admin` role) and optionally as a Flutter Web build.

---

## Screen Flow Overview

```
Admin Shell (Drawer Navigation)
    |
    +-- Dashboard
    |     |-- KPI Cards
    |     |-- Revenue Chart
    |     |-- Order Trends
    |     |-- Recent Activity
    |
    +-- Restaurants
    |     |-- Restaurant List
    |     |-- Add Restaurant
    |     |-- Edit Restaurant
    |     |-- Restaurant Detail
    |
    +-- Menu Management
    |     |-- Categories (per restaurant)
    |     |-- Menu Items (per restaurant)
    |     |-- Add/Edit Item
    |
    +-- Users
    |     |-- User List (all roles)
    |     |-- User Detail
    |     |-- Ban/Unban
    |
    +-- Delivery Partners
    |     |-- Verification Queue
    |     |-- Partner List
    |     |-- Partner Detail
    |     |-- Approve/Reject
    |
    +-- Orders
    |     |-- All Orders Table
    |     |-- Order Detail
    |     |-- Dispute Handling
    |
    +-- Promotions
    |     |-- Promotion List
    |     |-- Create Promotion
    |     |-- Edit Promotion
    |     |-- Usage Tracking
    |
    +-- Settings
          |-- Service Fees
          |-- Delivery Configuration
          |-- Tax Rates
          |-- App Version Control
          |-- Maintenance Mode
```

---

## 1. Dashboard

The admin dashboard provides a high-level view of the platform's health and activity.

### KPI Cards (Top Row)

Four key performance indicator cards displayed in a responsive grid:

| Card | Value | Subtitle | Icon |
| ---- | ----- | -------- | ---- |
| **Total Orders** | Count (today) | +12% vs yesterday | Shopping bag |
| **Revenue** | Sum in $ (today) | +8% vs yesterday | Dollar sign |
| **Active Users** | Count (currently online customers + partners) | -- | People |
| **Avg Delivery Time** | Minutes (today) | -3 min vs last week | Clock |

Each card shows:
- Large primary number
- Percentage change indicator (green up arrow or red down arrow)
- Comparison period label
- Tap to drill down into detailed view

### Revenue Chart

An interactive line chart (using `fl_chart`) showing revenue over time:

- **Time range selector**: 7 days, 30 days, 90 days, 1 year
- **Data lines**: Total revenue, delivery fees, service fees
- **Touch interaction**: Tap a point to see exact value and date
- **Y-axis**: Currency amount
- **X-axis**: Date labels

### Order Trends

A bar chart showing order volume:

- **Grouped bars**: Orders placed, delivered, cancelled per period
- **Time range**: Matches revenue chart selector
- **Color coding**: Green (delivered), Blue (placed), Red (cancelled)

### Recent Activity Feed

A scrollable list of recent platform events:

```
[10:42] New order #TF-A1B2 placed ($34.50) - Pizza Palace
[10:38] Delivery completed #TF-C3D4 - 28 min delivery time
[10:35] New delivery partner application: John Smith
[10:30] Restaurant "Burger Barn" went offline
[10:28] Refund processed #TF-E5F6 - $22.00
```

### Data Source

Dashboard data is fetched via the `getDashboardStats` Cloud Function, which aggregates data from Firestore. Stats are cached server-side for 5 minutes to reduce read costs.

---

## 2. Restaurant Management

### Restaurant List Screen

- **Search bar**: Search by restaurant name
- **Filters**: Cuisine type, active/inactive, open/closed, rating range
- **Sort**: By name, rating, order count, date added
- **List items**: Each shows restaurant image, name, cuisine, rating, status badges (Active/Inactive, Open/Closed)
- **Toggle buttons**: Quick toggle for Active and Open status directly from the list
- **"Add Restaurant"** FAB

### Add / Edit Restaurant Screen

A multi-section form:

**Basic Information:**
- Restaurant name (required)
- Description (required, max 500 characters)
- Cover image upload (required, with crop)
- Logo upload (optional, with crop)
- Phone number (required)
- Email (optional)

**Location:**
- Address fields (line 1, line 2, city, state, postal code, country)
- Google Maps widget for pin placement
- "Search Address" with autocomplete
- Geohash is computed automatically from coordinates

**Details:**
- Cuisine types (multi-select chips from predefined + custom)
- Price level (1-4 selector)
- Tags (free-form chips: vegan, halal, gluten-free, etc.)

**Delivery Settings:**
- Delivery fee (in dollars, stored as cents)
- Minimum order amount
- Estimated delivery time (min and max minutes)

**Operating Hours:**
- Day-by-day schedule editor
- Each day: Open time, Close time, Closed toggle
- "Copy to all days" shortcut

**Status:**
- Active toggle (visible to customers)
- Open toggle (accepting orders)
- Featured toggle (show in promotions)

### Restaurant Detail Screen

Read-only overview with all restaurant info, plus:

- **Order statistics**: Total orders, revenue, average rating (with charts)
- **Recent orders**: Last 10 orders for this restaurant
- **Reviews**: Recent reviews
- **Edit** and **Delete** buttons

---

## 3. Menu Management

Accessed from within a restaurant's detail screen.

### Category Management

- **List of categories** with drag-to-reorder (updates `sortOrder`)
- Each category shows: name, item count, active/inactive badge
- **Add Category**: Name, description, image (optional), sort order
- **Edit Category**: Same fields as add
- **Delete Category**: Confirmation dialog, warns if category has items
- **Toggle Active**: Quick enable/disable

### Menu Item Management

- **Grouped by category** with expandable sections
- Each item shows: image thumbnail, name, price, availability badge
- **Add Item** button per category
- **Edit**, **Duplicate**, **Delete** actions per item

### Add / Edit Menu Item Screen

**Basic Info:**
- Name (required)
- Description (required)
- Category (dropdown selector)
- Image upload (with crop and preview)

**Pricing:**
- Base price (required, in dollars)
- Discounted price (optional, must be less than base price)

**Details:**
- Preparation time (minutes)
- Calories
- Dietary flags: Vegetarian, Vegan, Gluten-Free (toggles)
- Spice level (0-3 selector)
- Tags (popular, new, chef-special)

**Customizations:**
A dynamic form builder for customization groups:

```
+------------------------------------------+
|  Customization Group: Size               |
|  Type: [Single] / Multiple               |
|  Required: [Yes] / No                    |
|                                          |
|  Options:                                |
|  +----+--------+--------+----+           |
|  |    | Name   | Price  |    |           |
|  +----+--------+--------+----+           |
|  | 1. | Small  | +$0.00 | X  |           |
|  | 2. | Medium | +$2.00 | X  |           |
|  | 3. | Large  | +$4.00 | X  |           |
|  +----+--------+--------+----+           |
|  [+ Add Option]                          |
|                                          |
|  [+ Add Another Customization Group]     |
+------------------------------------------+
```

- Each group: name, type (single/multiple), required flag, min/max selections
- Each option: name, price adjustment
- Drag to reorder options
- Delete individual options or entire groups

**Availability:**
- Available toggle (can be turned off when item is out of stock)
- Sort order within category

---

## 4. User Management

### User List Screen

- **Search**: By name, email, or phone number
- **Filter tabs**: All, Customers, Delivery Partners, Admins
- **Sort**: By name, join date, last active
- **Status filter**: Active / Banned
- **List items**: Avatar, name, email, role badge, join date, status

### User Detail Screen

- **Profile information**: All user fields
- **Activity summary**:
  - For customers: Total orders, total spent, last order date
  - For delivery partners: Total deliveries, rating, earnings, verification status
  - For admins: Role level, permissions
- **Order history**: Recent orders associated with this user
- **Reviews**: Reviews written by (customer) or received by (partner)
- **Action buttons**:
  - Ban / Unban (sets `isActive` to false/true)
  - Change Role (opens role selection dialog)
  - Send Notification
  - Delete Account (with confirmation, triggers full cleanup)

### Ban / Unban

- Ban: Sets `isActive = false`, shows reason input dialog
- Banned users cannot log in (checked at app launch via Firestore read)
- Unban: Sets `isActive = true`
- Both actions send a push notification to the user

---

## 5. Delivery Partner Management

### Verification Queue

A dedicated screen for pending partner applications:

```
+------------------------------------------+
|  VERIFICATION QUEUE (3 pending)          |
|                                          |
|  +------------------------------------+  |
|  | John Smith          Applied 2h ago |  |
|  | Motorcycle | License: DL-12345     |  |
|  | [View Documents]  [Approve][Reject]|  |
|  +------------------------------------+  |
|                                          |
|  +------------------------------------+  |
|  | Jane Doe            Applied 1d ago |  |
|  | Bicycle | License: DL-67890        |  |
|  | [View Documents]  [Approve][Reject]|  |
|  +------------------------------------+  |
+------------------------------------------+
```

### Document Review

Tapping "View Documents" opens a document viewer:

- **Driver's License**: Full-screen zoomable image
- **Government ID**: Full-screen zoomable image
- **Vehicle Registration**: Full-screen zoomable image (if applicable)
- Navigation between documents with swipe

### Approve Flow

1. Admin taps "Approve"
2. Confirmation dialog appears
3. Cloud Function `setUserRole` is called:
   - Sets custom claim `role: 'deliveryPartner'`
   - Updates `verificationStatus: 'approved'`
   - Updates `role: 'deliveryPartner'`
4. Push notification sent to partner: "Your application has been approved!"
5. Partner removed from verification queue

### Reject Flow

1. Admin taps "Reject"
2. Reason input dialog appears (required):
   - Predefined reasons: "Blurry document", "Expired license", "Invalid ID", "Other"
   - Custom text field for additional details
3. Updates `verificationStatus: 'rejected'` and `verificationNote`
4. Push notification sent to partner: "Your application needs attention. Please check the app."
5. Partner can resubmit documents

### Partner List

All approved delivery partners with:

- Name, vehicle type, rating, total deliveries
- Online/offline status
- Current order (if active)
- Last active timestamp
- Performance metrics

---

## 6. Order Management

### All Orders Table

A comprehensive order management view:

- **Search**: By order number, customer name, restaurant name
- **Filters**:
  - Status: All, Placed, Confirmed, Preparing, Ready, Picked Up, Delivered, Cancelled
  - Date range picker
  - Restaurant (dropdown)
  - Payment method: Card / Cash
  - Payment status: Paid / Pending / Refunded
- **Sort**: By date (default newest), total amount, status
- **Columns**: Order #, Customer, Restaurant, Items count, Total, Status, Payment, Date
- **Pagination**: 20 orders per page with page navigation

### Order Detail Screen (Admin View)

Everything from the customer order detail, plus:

- **Admin actions**:
  - Update status (force status change with dropdown)
  - Assign/reassign delivery partner (dropdown of online partners)
  - Process refund (full or partial, with reason)
  - Cancel order (with reason)
  - Add admin note
- **Full price breakdown** including fees and margins
- **Payment details**: Stripe payment intent ID, payment status, refund history
- **Status history**: Full timeline with who changed each status
- **Customer and partner info**: Links to their user detail screens

### Dispute Handling

When a customer reports an issue:

1. Order is flagged with a dispute marker
2. Admin can view the dispute reason and evidence
3. Resolution options:
   - Full refund to customer
   - Partial refund (specify amount)
   - Credit to customer wallet (future feature)
   - No action (with explanation)
4. Communication sent to customer with resolution
5. If delivery partner at fault, note added to partner's record

---

## 7. Promotions

### Promotion List Screen

- **Tabs**: Active, Scheduled (future start date), Expired
- Each promotion shows: code, description, discount value, usage count, date range
- **Toggle**: Quick activate/deactivate
- **"Create Promotion"** FAB

### Create / Edit Promotion Screen

**Basic Info:**
- Coupon code (uppercase, auto-generated or custom, unique validation)
- Description (displayed to customers)

**Discount Configuration:**
- Discount type: Percentage or Fixed Amount
- Discount value (percentage or dollar amount)
- Maximum discount amount (cap for percentage discounts)
- Minimum order amount

**Restrictions:**
- Applicable restaurants (multi-select, or "All Restaurants")
- Total usage limit (or unlimited)
- Per-user usage limit (default 1)

**Schedule:**
- Start date and time
- End date and time

**Preview:**
Live preview of how the coupon will appear to customers

### Usage Tracking

For each promotion, a detail view shows:

- Total uses vs usage limit
- Total discount given
- **Usage over time** chart
- **Top users** (who used it most, if per-user limit > 1)
- **Orders list**: All orders where this coupon was applied

---

## 8. App Configuration (Settings)

Editable fields that map to the `app_config/settings` Firestore document.

### Fee Configuration

| Setting | Field | Description |
| ------- | ----- | ----------- |
| Service Fee Percentage | `serviceFeePercentage` | Platform fee (e.g., 5%) |
| Minimum Service Fee | `serviceFeeMin` | Floor for service fee (cents) |
| Maximum Service Fee | `serviceFeeMax` | Cap for service fee (cents) |
| Default Delivery Fee | `defaultDeliveryFee` | Base delivery fee (cents) |
| Delivery Fee Per Km | `deliveryFeePerKm` | Additional per-km charge (cents) |

### Delivery Configuration

| Setting | Field | Description |
| ------- | ----- | ----------- |
| Max Delivery Radius | `maxDeliveryRadiusKm` | Maximum delivery distance (km) |
| Min Order Amount | `minOrderAmount` | Global minimum order (cents) |

### Tax Configuration

| Setting | Field | Description |
| ------- | ----- | ----------- |
| Tax Percentage | `taxPercentage` | Tax rate applied to subtotal |

### App Version Control

| Setting | Field | Description |
| ------- | ----- | ----------- |
| Current App Version | `currentAppVersion` | Latest available version |
| Force Update Version | `forceUpdateVersion` | Minimum required version |

When a user opens the app and their version is below `forceUpdateVersion`, they see a full-screen dialog directing them to update. Versions between `forceUpdateVersion` and `currentAppVersion` see a dismissible update suggestion.

### Maintenance Mode

| Setting | Field | Description |
| ------- | ----- | ----------- |
| Maintenance Mode | `maintenanceMode` | Boolean toggle |
| Maintenance Message | `maintenanceMessage` | Message shown to all users |

When enabled, all non-admin users see a maintenance screen instead of the app.

### Support & Legal

| Setting | Field | Description |
| ------- | ----- | ----------- |
| Support Email | `supportEmail` | Customer support email |
| Support Phone | `supportPhone` | Customer support phone |
| Terms URL | `termsUrl` | Link to terms of service |
| Privacy URL | `privacyUrl` | Link to privacy policy |

### Payout Configuration

| Setting | Field | Description |
| ------- | ----- | ----------- |
| Payout Day | `deliveryPartnerPayoutDay` | Day of week for partner payouts |

### Save Behavior

- Each setting change requires explicit "Save" confirmation.
- Changes are written to `app_config/settings` document.
- All clients observe changes in real-time via Firestore listeners.
- Critical changes (maintenance mode, force update) show a double-confirmation dialog.

---

## Admin Authentication

- Admin accounts require the `admin` custom claim.
- The admin shell is only accessible to users with `role == 'admin'`.
- GoRouter redirects non-admin users away from `/admin/*` routes.
- Sensitive actions (delete user, process refund) may require re-authentication.
- Admin activity is logged for audit purposes (future enhancement).

---

## Responsive Design

The admin panel is designed to work on both mobile and tablet/web:

| Screen Size | Layout |
| ----------- | ------ |
| Mobile (<600px) | Drawer navigation, single column, compact cards |
| Tablet (600-1200px) | Persistent side navigation, two-column layouts |
| Desktop/Web (>1200px) | Full side navigation, multi-column dashboard, data tables |

The Flutter Web build provides the best admin experience on desktop browsers.
