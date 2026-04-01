# Tuish Food

**Delicious food, delivered fast.**

Tuish Food is a full-featured food delivery platform built with Flutter and Firebase. It serves three distinct user roles -- Customers, Delivery Partners, and Administrators -- each with a dedicated experience tailored to their workflow.

---

## Tech Stack

| Layer              | Technology                              |
| ------------------ | --------------------------------------- |
| Framework          | Flutter 3.x (Dart 3.x)                 |
| Backend            | Firebase (Auth, Firestore, Functions, Storage, Cloud Messaging) |
| State Management   | Riverpod 2.x with code generation       |
| Navigation         | GoRouter 14.x                           |
| Maps & Tracking    | Google Maps Flutter, Geolocator, Geocoding |
| Payments           | Stripe (flutter_stripe + Cloud Functions)|
| Local Storage      | Hive (cart persistence, caching)        |
| Notifications      | Firebase Cloud Messaging + flutter_local_notifications |
| Error Handling     | dartz (Either, Failure)                 |
| Image Handling     | cached_network_image, image_picker      |
| Charts             | fl_chart                                |

---

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** >= 3.16.0 (`flutter --version`)
- **Dart SDK** >= 3.2.0 (bundled with Flutter)
- **Firebase CLI** >= 13.0.0 (`firebase --version`)
- **Node.js** >= 18.x (for Cloud Functions)
- **Android Studio** or **Xcode** (platform tooling)
- **Google Maps API Key** (Maps SDK for Android & iOS, Directions API, Geocoding API)
- **Stripe Account** (publishable key + secret key)

---

## Getting Started

```bash
# 1. Clone the repository
git clone https://github.com/your-org/tuish-food.git
cd tuish-food

# 2. Install Flutter dependencies
flutter pub get

# 3. Configure Firebase
firebase login
flutterfire configure

# 4. Set up environment variables
cp .env.example .env
# Edit .env with your API keys (Google Maps, Stripe, etc.)

# 5. Deploy Cloud Functions
cd functions
npm install
cd ..
firebase deploy --only functions

# 6. Deploy Firestore rules and indexes
firebase deploy --only firestore:rules,firestore:indexes

# 7. Run the app
flutter run
```

### Running on Specific Platforms

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web (admin panel)
flutter run -d chrome
```

### Build Flavors

```bash
# Development
flutter run --dart-define=ENVIRONMENT=dev

# Staging
flutter run --dart-define=ENVIRONMENT=staging

# Production
flutter run --dart-define=ENVIRONMENT=prod
```

---

## Project Structure

```
lib/
  core/               # Shared utilities, theme, constants, error handling
  features/           # Feature modules (features-first architecture)
    auth/             # Authentication & onboarding
    customer/         # Customer-facing screens & logic
    delivery/         # Delivery partner screens & logic
    admin/            # Admin panel screens & logic
    orders/           # Shared order logic
    chat/             # In-app messaging
    notifications/    # Push & local notifications
    tracking/         # Real-time delivery tracking
    payments/         # Stripe integration
  shared/             # Shared widgets, models, providers
  app.dart            # MaterialApp.router configuration
  main.dart           # Entry point
functions/            # Firebase Cloud Functions (TypeScript)
docs/                 # Project documentation
```

For a deep dive into the architecture, see [docs/architecture.md](docs/architecture.md).

---

## Documentation

| Document | Description |
| -------- | ----------- |
| [Architecture](docs/architecture.md) | Clean architecture, features-first structure, dependency rules |
| [Firebase Schema](docs/firebase-schema.md) | Complete Firestore collections, fields, indexes, security rules |
| [Authentication](docs/authentication.md) | Auth methods, custom claims, role assignment, security rules |
| [Customer Features](docs/customer-features.md) | Home, restaurants, cart, checkout, tracking, reviews, profile |
| [Delivery Partner Features](docs/delivery-partner-features.md) | Registration, active delivery, navigation, earnings |
| [Admin Features](docs/admin-features.md) | Dashboard, restaurant/user/order management, promotions, config |
| [API Contracts](docs/api-contracts.md) | Cloud Functions signatures, request/response types, error codes |
| [State Management](docs/state-management.md) | Riverpod patterns, provider hierarchy, code examples |
| [Navigation](docs/navigation.md) | GoRouter config, route tree, shell routes, guards, deep linking |
| [Real-time Tracking](docs/realtime-tracking.md) | GPS tracking, Google Maps, ETA, background location, assignment |
| [Payments](docs/payments.md) | Stripe integration, checkout flow, refunds, fee breakdown |
| [Notifications](docs/notifications.md) | FCM setup, notification types, deep linking, preferences |
| [Deployment](docs/deployment.md) | Build flavors, CI/CD, store deployment, versioning |
| [UI Design System](docs/ui-design-system.md) | Colors, typography, spacing, components, dark mode, accessibility |

---

## Screenshots

> Screenshots will be added here as the UI is implemented.

| Customer Home | Restaurant Detail | Order Tracking |
| :-----------: | :---------------: | :------------: |
| *Coming soon* | *Coming soon*     | *Coming soon*  |

| Delivery Dashboard | Admin Panel | Chat |
| :----------------: | :---------: | :--: |
| *Coming soon*      | *Coming soon* | *Coming soon* |

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please read the architecture documentation before contributing to ensure consistency with the project's patterns.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2026 Tuish Food

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
# tuish-food
