# Customer Features

This document describes all customer-facing features in the Tuish Food app, including screen flows, interactions, and key implementation details.

---

## Screen Flow Overview

```
Login/Signup
    |
    v
Customer Shell (Bottom Navigation)
    |
    +-- Home Tab
    |     |-- Home Screen (restaurants, categories, promotions, search)
    |     |-- Restaurant Detail Screen
    |     |     |-- Menu Item Detail (customization bottom sheet)
    |     |-- Search Results Screen
    |     |-- Category Restaurants Screen
    |
    +-- Orders Tab
    |     |-- Order History Screen
    |     |-- Order Detail Screen
    |     |     |-- Order Tracking Screen (real-time map)
    |     |     |-- Chat Screen (with delivery partner)
    |     |-- Review Screen
    |
    +-- Cart Tab
    |     |-- Cart Screen
    |     |-- Checkout Screen
    |     |     |-- Address Selection Screen
    |     |     |-- Payment Method Screen
    |     |     |-- Order Confirmation Screen
    |
    +-- Profile Tab
          |-- Profile Screen
          |-- Edit Profile Screen
          |-- Manage Addresses Screen
          |     |-- Add/Edit Address Screen
          |-- Favorites Screen
          |-- Notification Settings Screen
          |-- About / Help Screen
```

---

## 1. Home Screen

The home screen is the customer's primary entry point. It is designed for quick restaurant discovery.

### Layout (Top to Bottom)

1. **Location Bar**: Shows current delivery address. Tapping opens address selection.
2. **Search Bar**: Tapping navigates to dedicated search screen with auto-suggestions.
3. **Promotional Carousel**: Horizontal `PageView` of active promotions with auto-scroll (5 second interval). Each banner links to a restaurant or coupon.
4. **Category Row**: Horizontal scroll of cuisine categories (Pizza, Burgers, Sushi, Indian, Chinese, Healthy, etc.) with icons. Tapping filters restaurants.
5. **Featured Restaurants**: Horizontal scroll of restaurants marked `isFeatured: true`. Card shows image, name, rating, delivery time, delivery fee.
6. **Nearby Restaurants**: Vertical list of restaurants sorted by distance. Infinite scroll with pagination (10 per page). Each card shows:
   - Restaurant image
   - Name, cuisine types
   - Rating (stars + number)
   - Estimated delivery time range
   - Delivery fee (or "Free Delivery" badge)
   - Distance
   - Open/Closed status badge

### Data Loading

- Location is obtained via `Geolocator` on first launch (with permission request).
- Restaurants are queried by geohash range from Firestore.
- Promotions are loaded from the `promotions` collection where `isActive == true` and `endDate > now`.
- Pull-to-refresh reloads all sections.

### Skeleton Loading

While data loads, the screen shows animated skeleton placeholders (`LoadingSkeleton` widgets) matching the layout of each section.

---

## 2. Restaurant Detail Screen

Displayed when a customer taps on a restaurant card.

### Header Section

- **Hero image**: Full-width restaurant cover image with gradient overlay.
- **Restaurant name**, cuisine types, price level indicators.
- **Rating**: Star rating with review count. Tapping opens reviews list.
- **Info row**: Delivery time, delivery fee, minimum order.
- **Operating hours**: Current status (Open/Closed) with schedule expandable.
- **Favorite button**: Heart icon to save/unsave from favorites.

### Menu Section

- **Category tabs**: Horizontal scrollable tab bar (Appetizers, Mains, Drinks, Desserts, etc.).
- **Menu items list**: Grouped by category. Each item shows:
  - Item image (if available)
  - Name
  - Description (2 lines, expandable)
  - Price (with strikethrough if discounted)
  - Dietary badges (vegetarian, vegan, gluten-free, spice level)
  - Add button (+) which opens the item detail bottom sheet

### Reviews Section

- **Summary**: Average rating, rating distribution bar chart (5 stars to 1 star).
- **Review list**: Most recent reviews with reviewer name, date, rating, comment, and photos.
- **"See All Reviews"** button navigates to full paginated reviews screen.

---

## 3. Menu Item Detail

Displayed as a bottom sheet when a customer taps a menu item or the (+) button.

### Layout

1. **Item image** (full width at top of bottom sheet).
2. **Name and price**.
3. **Description** (full text).
4. **Customization groups** (dynamically rendered based on item's `customizations` array):
   - **Single selection (radio)**: "Choose Size" -- Small / Medium / Large with price adjustments.
   - **Multiple selection (checkbox)**: "Add Toppings" -- each option with price adjustment, respecting min/max selections.
   - Required groups show a "Required" badge and must be completed before adding to cart.
5. **Special instructions**: Free-text field for customer notes.
6. **Quantity selector**: Minus/Plus buttons (minimum 1, maximum 20).
7. **Add to Cart button**: Shows total price including customizations. Disabled until all required customizations are selected.

### Price Calculation

```
itemTotal = (basePrice + sum(selectedOptionAdjustments)) * quantity
```

---

## 4. Cart

### Cart Screen

- **Restaurant header**: Shows which restaurant the items are from. All items must be from the same restaurant.
- **Item list**: Each item shows name, customizations summary, quantity, total price. Swipe left to delete. Tap to edit (reopens item detail sheet with current selections).
- **Quantity controls**: Inline +/- buttons for each item.
- **Coupon field**: Text field with "Apply" button to validate and apply a coupon code.
- **Price summary**:
  - Subtotal
  - Delivery Fee
  - Service Fee
  - Tax
  - Discount (if coupon applied)
  - **Total**
- **Checkout button**: Navigates to checkout. Disabled if below minimum order amount (shows how much more needed).

### Restaurant Switch Warning

If the customer tries to add an item from a different restaurant while the cart has items, a dialog appears:

> "Your cart contains items from [Restaurant A]. Adding items from [Restaurant B] will clear your current cart. Continue?"

Options: "Cancel" or "Clear Cart & Add".

### Cart Persistence (Hive)

The cart is persisted locally using Hive so it survives app restarts:

```dart
@HiveType(typeId: 0)
class CartItemModel extends HiveObject {
  @HiveField(0) final String itemId;
  @HiveField(1) final String restaurantId;
  @HiveField(2) final String name;
  @HiveField(3) final String? imageUrl;
  @HiveField(4) final int basePrice;
  @HiveField(5) final List<CartCustomization> customizations;
  @HiveField(6) int quantity;
  @HiveField(7) final String? specialInstructions;
}
```

Cart state is managed by a Riverpod `NotifierProvider` that reads from and writes to Hive on every change.

---

## 5. Checkout

### Checkout Screen Layout

1. **Delivery Address**:
   - Shows selected address with edit button.
   - Tapping opens address selection screen (list of saved addresses + "Add New Address").
   - Default address is pre-selected.

2. **Delivery Time**:
   - Estimated delivery time range (e.g., "25-35 min").
   - Option for scheduled delivery (date/time picker) -- future enhancement.

3. **Order Items Summary**:
   - Collapsed list of items with quantities and prices. Expandable to see full details.

4. **Special Instructions**:
   - Text field for order-level notes to the restaurant.

5. **Tip for Delivery Partner**:
   - Quick-select buttons: No tip, $2, $5, $8, Custom.
   - Custom opens a number input.

6. **Coupon Code**:
   - If already applied from cart, shown with discount amount and remove button.
   - If not, text field to apply.

7. **Payment Method**:
   - Shows selected payment method with change button.
   - Options: Saved cards (via Stripe), Add new card, Cash on Delivery.

8. **Price Breakdown**:
   - Subtotal
   - Delivery Fee
   - Service Fee
   - Tax
   - Tip
   - Discount
   - **Total** (bold, large)

9. **Place Order Button**:
   - Shows total amount.
   - On tap: validates everything, creates PaymentIntent (if card), confirms payment, creates order document in Firestore.
   - Shows loading indicator during processing.
   - On success: navigates to Order Confirmation screen.
   - On failure: shows error with retry option.

### Checkout Flow

```
Customer taps "Place Order"
    |
    v
Validate: address, payment method, minimum order
    |
    v
Call Cloud Function: calculateFees
    |  (recalculates server-side to prevent tampering)
    v
Payment method == 'card'?
    |
    +-- Yes --> Call CF: createPaymentIntent
    |              |
    |              v
    |           flutter_stripe.confirmPayment(clientSecret)
    |              |
    |              +-- Success --> Create order (paymentStatus: 'paid')
    |              +-- Failure --> Show error, do not create order
    |
    +-- No (Cash) --> Create order (paymentStatus: 'pending')
    |
    v
Order created in Firestore (status: 'placed')
    |
    v
Cloud Function: onOrderCreated triggers
    |  - Sends notification to restaurant (future: auto-assign delivery partner)
    |  - Creates chat document
    v
Navigate to Order Confirmation Screen
```

---

## 6. Order Tracking

After placing an order, the customer can track it in real-time.

### Status Timeline

A vertical stepper showing each status with timestamp:

```
(o) Order Placed         10:00 AM
(o) Confirmed            10:02 AM
(o) Preparing            10:03 AM
( ) Ready for Pickup     --
( ) Picked Up            --
( ) Delivered             --
```

Active step is highlighted with animation. Completed steps show checkmarks.

### Real-Time Map

When the order status is `pickedUp`, a Google Map appears showing:

- **Customer location** (destination pin)
- **Delivery partner location** (custom car/bike marker, updates every 5 seconds)
- **Polyline route** from partner to customer
- **ETA** displayed above the map and updates periodically

The map auto-zooms to fit both markers with padding.

### Delivery Partner Info Card

When a delivery partner is assigned:

- Partner name and photo
- Vehicle type
- Rating
- **Call button**: Opens phone dialer
- **Chat button**: Opens in-app chat

### Order Detail

Expandable section showing:

- Restaurant name
- All ordered items with quantities
- Price breakdown
- Special instructions
- Delivery address

### Cancel Order

Available only when status is `placed` or `confirmed`:

- "Cancel Order" button opens confirmation dialog with reason selection.
- On cancel: order status set to `cancelled`, refund initiated if paid by card.

---

## 7. Order History

### Order History Screen

- **Tab bar**: "Active" and "Past" tabs.
- **Active orders**: Orders with status `placed` through `pickedUp`. Tapping opens order tracking.
- **Past orders**: Orders with status `delivered` or `cancelled`. Sorted by date descending. Paginated.
- Each order card shows:
  - Restaurant name and logo
  - Order date and time
  - Number of items and total price
  - Status badge (color-coded)
  - "Reorder" button (for delivered orders)
  - "Track" button (for active orders)

### Order Detail Screen

Full order details including:

- All items with customizations
- Complete price breakdown
- Delivery address
- Status history with timestamps
- Delivery partner info (if assigned)
- Receipt / invoice option

### Reorder

Tapping "Reorder" on a past order:

1. Checks if the restaurant is currently open and active.
2. Checks if all items are still available.
3. Adds available items to cart with same customizations.
4. Shows warning for any unavailable items.
5. Navigates to cart screen.

---

## 8. Reviews

After an order is delivered, the customer is prompted to rate:

### Review Screen

Two review sections in sequence:

**1. Restaurant Review**
- Star rating (1-5, half stars allowed)
- Sub-ratings:
  - Food Quality
  - Portion Size
  - Value for Money
  - Packaging
- Written comment (optional, max 500 characters)
- Photo upload (optional, up to 3 photos)

**2. Delivery Partner Review**
- Star rating (1-5, half stars allowed)
- Sub-ratings:
  - Speed
  - Communication
  - Food Condition
- Written comment (optional, max 500 characters)

### Review Submission

On submit:
- Creates review document(s) in `reviews` collection.
- Cloud Function `onReviewCreated` triggers:
  - Updates restaurant's `rating` and `reviewCount` (running average).
  - Updates delivery partner's `rating` and `totalRatings`.
- Sets `customerRated: true` on the order to prevent duplicate reviews.

---

## 9. Profile

### Profile Screen

- **Profile header**: Photo, name, email, phone. Edit button.
- **Menu items**:
  - My Addresses (manage saved addresses)
  - Favorites (saved restaurants)
  - Payment Methods (manage cards via Stripe)
  - Notification Settings
  - Help & Support
  - Terms of Service
  - Privacy Policy
  - About Tuish Food
  - Sign Out
  - Delete Account (at bottom, red text)

### Edit Profile Screen

- Profile photo (tap to change, image_picker for camera/gallery)
- Display name (text field)
- Phone number (with OTP verification if changing)
- Email (read-only or with re-authentication to change)
- Save button

### Manage Addresses Screen

- List of saved addresses with label, full address, and default badge.
- Each address has edit and delete options.
- "Add New Address" button.
- Set as default option.

### Add/Edit Address Screen

- Google Maps widget for pin placement (drag to adjust).
- Address search with autocomplete (Google Places API).
- Form fields: Label, Address Line 1, Address Line 2, City, State, Postal Code.
- Delivery instructions text field.
- "Use Current Location" button.
- Save button.

---

## 10. Favorites

### Favorites Screen

- Grid or list view of saved restaurants.
- Each card matches the home screen restaurant card design.
- Tapping opens restaurant detail.
- Swipe to remove from favorites (or toggle heart icon).
- Empty state: "No favorites yet. Browse restaurants and tap the heart icon to save your favorites."

### Implementation

Favorites are stored as an array of restaurant IDs in the user document (`favoriteRestaurants`). The favorites screen queries restaurants by these IDs.

```dart
@riverpod
Future<List<RestaurantEntity>> favoriteRestaurants(
  FavoriteRestaurantsRef ref,
) async {
  final user = await ref.watch(userProfileProvider.future);
  if (user.favoriteRestaurants.isEmpty) return [];

  // Firestore 'in' query supports up to 30 items
  // Batch if needed
  final restaurants = await ref
      .watch(restaurantRepositoryProvider)
      .getRestaurantsByIds(user.favoriteRestaurants);

  return restaurants.fold(
    (failure) => throw failure,
    (list) => list,
  );
}
```

---

## Search

### Search Screen

- **Search field** with auto-focus and real-time suggestions.
- **Recent searches** shown when field is empty (stored locally in Hive).
- **Suggestions** as user types: restaurant names and cuisine types.
- **Results**: List of matching restaurants with relevance sorting.
- **Filters** (bottom sheet):
  - Cuisine type (multi-select chips)
  - Price level (1-4 slider)
  - Rating (minimum stars)
  - Delivery fee (max amount)
  - Dietary options (vegetarian, vegan, gluten-free)
  - Sort by: Relevance, Rating, Delivery Time, Distance, Price

### Search Implementation

Client-side search uses Firestore queries with `orderBy` and `startAt`/`endAt` for prefix matching on restaurant names and `array-contains-any` for cuisine types. For more advanced full-text search, Algolia or Typesense integration is planned as a future enhancement.

---

## Notification Handling

When a customer receives a notification (e.g., order status update):

| App State | Behavior |
| --------- | -------- |
| Foreground | In-app banner notification (flutter_local_notifications) with tap to navigate |
| Background | System notification tray, tap opens order tracking screen |
| Terminated | System notification tray, tap cold-launches app and navigates to order |

See [notifications.md](notifications.md) for full details.
