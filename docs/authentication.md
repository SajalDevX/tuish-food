# Authentication

This document covers authentication methods, user role management, custom claims, security rules, and the complete auth flow for Tuish Food.

---

## Supported Authentication Methods

| Method | Package | Use Case |
| ------ | ------- | -------- |
| **Email / Password** | `firebase_auth` | Primary sign-up and sign-in method |
| **Phone OTP** | `firebase_auth` | Phone number verification, can be linked to existing account |
| **Google Sign-In** | `google_sign_in` + `firebase_auth` | Social login for faster onboarding |

All methods result in a Firebase Auth user. After authentication, a Firestore `users/{uid}` document is created (if new) and a custom claim for `role` is assigned.

---

## Custom Claims Strategy

Firebase Custom Claims are used for role-based access control. They are set via Cloud Functions and embedded in the Firebase Auth token.

```typescript
// Custom claims structure
interface TuishCustomClaims {
  role: 'customer' | 'deliveryPartner' | 'admin';
}
```

### Why Custom Claims?

- **Security rules**: Firestore and Storage rules can check `request.auth.token.role` without reading the user document.
- **Client-side**: The Flutter app reads claims from the ID token to determine which shell/navigation to show.
- **Performance**: No extra Firestore read needed to determine user role on every authenticated request.

### Claim Limits

Firebase custom claims have a **1000 byte limit** per user. The `role` field is well within this limit.

---

## Registration Flows

### Customer Registration

```
+-------------------+     +-------------------+     +-------------------+
|   Sign Up Screen  | --> | Firebase Auth      | --> | Cloud Function:   |
|   (email/Google)  |     | createUser         |     | onUserCreated     |
+-------------------+     +-------------------+     +-------------------+
                                                            |
                                                            v
                                                    +-------------------+
                                                    | Set custom claim  |
                                                    | role: 'customer'  |
                                                    +-------------------+
                                                            |
                                                            v
                                                    +-------------------+
                                                    | Create Firestore  |
                                                    | users/{uid} doc   |
                                                    +-------------------+
                                                            |
                                                            v
                                                    +-------------------+
                                                    | Client: force     |
                                                    | token refresh     |
                                                    +-------------------+
                                                            |
                                                            v
                                                    +-------------------+
                                                    | Navigate to       |
                                                    | Customer Shell    |
                                                    +-------------------+
```

Customer registration is automatic. As soon as a user signs up, they are assigned the `customer` role.

### Delivery Partner Registration

```
+-------------------+     +-------------------+     +-------------------+
|  Sign Up Screen   | --> | Firebase Auth      | --> | Cloud Function:   |
|  (as customer     |     | createUser         |     | onUserCreated     |
|  initially)       |     |                    |     | role: 'customer'  |
+-------------------+     +-------------------+     +-------------------+
        |
        v
+-------------------+
| Partner Signup    |
| Screen            |
| - Upload license  |
| - Upload ID       |
| - Vehicle info    |
+-------------------+
        |
        v
+-------------------+     +-------------------+
| Firestore update  | --> | verificationStatus |
| Add partner fields|     | = 'pending'        |
+-------------------+     +-------------------+
        |
        v
+-------------------+
| Waiting Screen    |  <-- "Your application is under review"
+-------------------+
        |
        v (Admin approves)
+-------------------+     +-------------------+
| Cloud Function:   | --> | Set custom claim   |
| setUserRole       |     | role:              |
| (admin callable)  |     | 'deliveryPartner'  |
+-------------------+     +-------------------+
        |
        v
+-------------------+
| Notification sent |
| to partner        |
+-------------------+
        |
        v
+-------------------+
| Partner reopens   |
| app, token        |
| refreshed         |
+-------------------+
        |
        v
+-------------------+
| Navigate to       |
| Delivery Shell    |
+-------------------+
```

### Admin Account Creation

Admin accounts are **never** created through the public registration flow. They are created through one of two methods:

1. **Bootstrap (first admin)**: A dedicated Cloud Function or Firebase Admin SDK script sets the first admin.
2. **Existing admin creates new admin**: An existing admin calls the `setUserRole` Cloud Function.

---

## Role Assignment Flow

```dart
// Cloud Function: setUserRole (callable, admin-only)
exports.setUserRole = functions.https.onCall(async (data, context) => {
  // Verify caller is admin
  if (!context.auth?.token?.role || context.auth.token.role !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can set user roles.'
    );
  }

  const { userId, role } = data;

  // Validate role
  if (!['customer', 'deliveryPartner', 'admin'].includes(role)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Invalid role.'
    );
  }

  // Additional check for delivery partner
  if (role === 'deliveryPartner') {
    const userDoc = await admin.firestore().doc(`users/${userId}`).get();
    if (userDoc.data()?.verificationStatus !== 'pending') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Partner must have pending verification status.'
      );
    }

    // Update verification status
    await admin.firestore().doc(`users/${userId}`).update({
      verificationStatus: 'approved',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  // Set custom claim
  await admin.auth().setCustomUserClaims(userId, { role });

  // Update Firestore user doc
  await admin.firestore().doc(`users/${userId}`).update({
    role: role,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});
```

---

## Token Refresh Strategy

After a role change, the client must refresh its ID token to get the new custom claims.

```dart
// Force token refresh after role change
Future<void> refreshTokenAndCheckRole() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Force refresh to get new custom claims
  final idTokenResult = await user.getIdTokenResult(true);

  final role = idTokenResult.claims?['role'] as String?;

  // Navigate based on new role
  if (role != null) {
    ref.read(userRoleProvider.notifier).state = UserRole.fromString(role);
  }
}
```

### When to Refresh

| Event | Action |
| ----- | ------ |
| App launch | `getIdTokenResult(true)` to ensure fresh claims |
| After sign-in | Claims already fresh |
| After admin changes a user's role | The affected user must be notified to relaunch or force-refresh |
| Periodic (optional) | Token auto-refreshes every ~1 hour by Firebase SDK |

---

## Auth Flow Diagram (App Launch)

```
App Launch
    |
    v
Check FirebaseAuth.currentUser
    |
    +-- null --> Show Login Screen
    |
    +-- exists
         |
         v
    getIdTokenResult(true)
         |
         v
    Read custom claims
         |
         +-- role == null --> Show Role Selection / Error
         |
         +-- role == 'customer'
         |       |
         |       v
         |   Check if onboarding complete
         |       |
         |       +-- no  --> Onboarding Screen
         |       +-- yes --> Customer Shell
         |
         +-- role == 'deliveryPartner'
         |       |
         |       v
         |   Check verificationStatus
         |       |
         |       +-- 'pending'  --> Verification Pending Screen
         |       +-- 'rejected' --> Resubmit Documents Screen
         |       +-- 'approved' --> Delivery Shell
         |
         +-- role == 'admin'
                 |
                 v
             Admin Shell
```

---

## Firestore Security Rules for Roles

The custom claims are available in Firestore security rules via `request.auth.token`:

```javascript
// Check if user is authenticated
function isAuthenticated() {
  return request.auth != null;
}

// Check specific role
function hasRole(role) {
  return isAuthenticated() && request.auth.token.role == role;
}

// Check if user is admin
function isAdmin() {
  return hasRole('admin');
}

// Example: Only admins can create restaurants
match /restaurants/{restaurantId} {
  allow read: if isAuthenticated();
  allow create, update, delete: if isAdmin();
}

// Example: Customers can only read/write their own orders
match /orders/{orderId} {
  allow create: if hasRole('customer');
  allow read: if resource.data.customerId == request.auth.uid
    || resource.data.deliveryPartnerId == request.auth.uid
    || isAdmin();
  allow update: if resource.data.customerId == request.auth.uid
    || resource.data.deliveryPartnerId == request.auth.uid
    || isAdmin();
}
```

---

## Logout Flow

```dart
Future<void> signOut() async {
  // 1. Remove FCM token from user document
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.doc('users/${user.uid}').update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    }
  }

  // 2. Clear local state
  await Hive.box('cart').clear();
  ref.invalidate(userProfileProvider);
  ref.invalidate(cartProvider);

  // 3. Sign out from Firebase Auth
  await GoogleSignIn().signOut(); // If Google sign-in was used
  await FirebaseAuth.instance.signOut();

  // 4. GoRouter redirect will handle navigation to login
}
```

---

## Account Deletion

To comply with app store requirements, users can delete their accounts:

```dart
Future<void> deleteAccount() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // 1. Call Cloud Function to clean up server-side data
  final callable = FirebaseFunctions.instance.httpsCallable('deleteUserData');
  await callable.call({'userId': user.uid});

  // 2. Delete Firebase Auth account
  await user.delete();

  // 3. Clear local storage
  await Hive.deleteFromDisk();

  // 4. Navigate to login
}
```

The `deleteUserData` Cloud Function handles:
- Deleting the user's Firestore document and subcollections
- Deleting uploaded files from Firebase Storage
- Cancelling any pending orders
- Removing the user from chat participants
- Deleting the Stripe customer (if applicable)

---

## First Admin Bootstrap

When deploying the app for the first time, there is no admin to create other admins. Use the Firebase Admin SDK to bootstrap the first admin:

```typescript
// scripts/bootstrap-admin.ts
// Run with: npx ts-node scripts/bootstrap-admin.ts

import * as admin from 'firebase-admin';

admin.initializeApp();

async function bootstrapAdmin(email: string) {
  // Find or create the user
  let user;
  try {
    user = await admin.auth().getUserByEmail(email);
  } catch {
    user = await admin.auth().createUser({
      email,
      password: 'ChangeThisPassword123!',
    });
  }

  // Set admin custom claim
  await admin.auth().setCustomUserClaims(user.uid, { role: 'admin' });

  // Create/update Firestore document
  await admin.firestore().doc(`users/${user.uid}`).set({
    uid: user.uid,
    email: email,
    displayName: 'Super Admin',
    role: 'admin',
    adminLevel: 'superAdmin',
    permissions: ['all'],
    isActive: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  console.log(`Admin bootstrapped: ${user.uid} (${email})`);
}

bootstrapAdmin('admin@tuishfood.com');
```

Run once during initial deployment:

```bash
cd functions
npx ts-node ../scripts/bootstrap-admin.ts
```

---

## Security Considerations

| Concern | Mitigation |
| ------- | ---------- |
| Role escalation | Custom claims can only be set by Cloud Functions with admin verification |
| Token theft | Firebase tokens expire every 1 hour; refresh tokens are bound to device |
| Brute force | Firebase Auth has built-in rate limiting for failed sign-in attempts |
| Stale claims | Force token refresh on app launch and after known role changes |
| Account enumeration | Firebase Auth's email enumeration protection is enabled |
| Phone abuse | Enable App Check to prevent abuse of phone auth SMS |
| Unverified email | Require email verification before allowing order placement |
