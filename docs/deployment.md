# Deployment

This document covers the build, deployment, and release processes for Tuish Food, including build flavors, environment configuration, app store deployment, CI/CD pipelines, and version management.

---

## Build Flavors

Tuish Food uses three build flavors corresponding to different environments:

| Flavor | Firebase Project | Use Case |
| ------ | ---------------- | -------- |
| **dev** | `tuish-food-dev` | Local development, debugging |
| **staging** | `tuish-food-staging` | QA testing, pre-release validation |
| **prod** | `tuish-food-prod` | Production release |

---

## Environment Configuration

### Dart Defines

Environment variables are passed at build time using `--dart-define` or `--dart-define-from-file`:

```bash
# Using individual defines
flutter run --dart-define=ENVIRONMENT=dev \
            --dart-define=GOOGLE_MAPS_API_KEY=AIza... \
            --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...

# Using .env file (recommended)
flutter run --dart-define-from-file=.env.dev
```

### Environment Files

```
project-root/
  .env.dev          # Development environment
  .env.staging      # Staging environment
  .env.prod         # Production environment
  .env.example      # Template (committed to git)
```

**`.env.example`:**

```
ENVIRONMENT=dev
GOOGLE_MAPS_API_KEY=your_google_maps_key
STRIPE_PUBLISHABLE_KEY=your_stripe_key
SUPPORT_EMAIL=support@tuishfood.com
```

**Important:** `.env.dev`, `.env.staging`, and `.env.prod` are listed in `.gitignore` and never committed.

### Reading Environment Variables in Dart

```dart
class EnvConfig {
  static const environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );

  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );

  static const stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
  );

  static bool get isDev => environment == 'dev';
  static bool get isStaging => environment == 'staging';
  static bool get isProd => environment == 'prod';
}
```

---

## Firebase Projects per Environment

Each environment uses a separate Firebase project for complete isolation:

| Environment | Project ID | Firestore | Auth | Functions | Storage |
| ----------- | ---------- | --------- | ---- | --------- | ------- |
| dev | `tuish-food-dev` | Separate DB | Separate users | Separate deployment | Separate bucket |
| staging | `tuish-food-staging` | Separate DB | Separate users | Separate deployment | Separate bucket |
| prod | `tuish-food-prod` | Separate DB | Separate users | Separate deployment | Separate bucket |

### FlutterFire Configuration

```bash
# Generate config for each environment
flutterfire configure --project=tuish-food-dev --out=lib/firebase_options_dev.dart
flutterfire configure --project=tuish-food-staging --out=lib/firebase_options_staging.dart
flutterfire configure --project=tuish-food-prod --out=lib/firebase_options_prod.dart
```

### Dynamic Firebase Initialization

```dart
// main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final options = _getFirebaseOptions();
  await Firebase.initializeApp(options: options);

  runApp(const ProviderScope(child: TuishFoodApp()));
}

FirebaseOptions _getFirebaseOptions() {
  switch (EnvConfig.environment) {
    case 'prod':
      return FirebaseOptionsProd.currentPlatform;
    case 'staging':
      return FirebaseOptionsStaging.currentPlatform;
    default:
      return FirebaseOptionsDev.currentPlatform;
  }
}
```

---

## Android Build

### Signing Configuration

```groovy
// android/app/build.gradle

android {
    signingConfigs {
        debug {
            storeFile file('debug.keystore')
            storePassword 'android'
            keyAlias 'androiddebugkey'
            keyPassword 'android'
        }
        release {
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
        }
    }

    buildTypes {
        debug {
            signingConfig signingConfigs.debug
            applicationIdSuffix '.dev'
            versionNameSuffix '-dev'
        }
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### Keystore

```bash
# Generate release keystore (one-time)
keytool -genkey -v -keystore tuish-food-release.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias tuish-food
```

**`android/key.properties`** (not committed to git):

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=tuish-food
storeFile=/path/to/tuish-food-release.keystore
```

### Build Commands

```bash
# Debug APK
flutter build apk --debug --dart-define-from-file=.env.dev

# Release APK
flutter build apk --release --dart-define-from-file=.env.prod

# App Bundle (for Play Store)
flutter build appbundle --release --dart-define-from-file=.env.prod

# Split APKs per ABI (for testing)
flutter build apk --release --split-per-abi --dart-define-from-file=.env.prod
```

### Play Store Deployment

1. Build the app bundle: `flutter build appbundle --release --dart-define-from-file=.env.prod`
2. Upload `build/app/outputs/bundle/release/app-release.aab` to Google Play Console
3. Fill in store listing, screenshots, and content rating
4. Submit for review

---

## iOS Build

### Certificates and Provisioning

| Item | Type | Purpose |
| ---- | ---- | ------- |
| Development Certificate | iOS Development | Local testing on device |
| Distribution Certificate | iOS Distribution | App Store and TestFlight |
| Development Profile | Development | Device testing |
| Ad Hoc Profile | Ad Hoc | Internal distribution |
| App Store Profile | App Store | Production release |

### Xcode Configuration

```
ios/Runner.xcodeproj
  Signing & Capabilities:
    Team: Your Apple Developer Team
    Bundle Identifier: com.tuishfood.app
    Signing Certificate: Apple Distribution
    Provisioning Profile: Tuish Food App Store
```

### Build Commands

```bash
# Debug build
flutter build ios --debug --dart-define-from-file=.env.dev

# Release build
flutter build ios --release --dart-define-from-file=.env.prod

# Build IPA for distribution
flutter build ipa --release --dart-define-from-file=.env.prod
```

### App Store Deployment

1. Build the IPA: `flutter build ipa --release --dart-define-from-file=.env.prod`
2. Open `build/ios/ipa/` in Finder
3. Upload to App Store Connect via Transporter or `xcrun altool`
4. Configure TestFlight for beta testing
5. Submit for App Store review

### Automated Upload

```bash
# Upload to App Store Connect
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/tuish_food.ipa \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

---

## Web Build (Admin Panel)

The admin panel can be deployed as a Flutter Web app for desktop browser access.

```bash
# Build for web
flutter build web --release --dart-define-from-file=.env.prod

# Output: build/web/
```

### Hosting Options

| Option | Command | URL |
| ------ | ------- | --- |
| Firebase Hosting | `firebase deploy --only hosting` | `admin.tuishfood.com` |
| Custom server | Copy `build/web/` to server | Your domain |

### Firebase Hosting Configuration

```json
// firebase.json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      }
    ]
  }
}
```

---

## Cloud Functions Deployment

```bash
# Deploy all functions
cd functions && npm run build && cd ..
firebase deploy --only functions --project tuish-food-prod

# Deploy specific function
firebase deploy --only functions:onOrderCreated --project tuish-food-prod

# Deploy functions with environment config
firebase functions:config:set stripe.secret_key="sk_live_..." \
  --project tuish-food-prod
```

### Functions Environment Variables

```bash
# Set environment variables for Cloud Functions
firebase functions:secrets:set STRIPE_SECRET_KEY --project tuish-food-prod
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET --project tuish-food-prod
firebase functions:secrets:set GOOGLE_MAPS_SERVER_KEY --project tuish-food-prod
```

---

## Firestore Rules and Storage Rules Deployment

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules --project tuish-food-prod

# Deploy Firestore indexes
firebase deploy --only firestore:indexes --project tuish-food-prod

# Deploy Storage rules
firebase deploy --only storage --project tuish-food-prod

# Deploy everything Firebase
firebase deploy --project tuish-food-prod
```

---

## CI/CD with GitHub Actions

### Workflow Overview

| Trigger | Workflow | Actions |
| ------- | -------- | ------- |
| Pull Request | `pr-check.yml` | Lint, test, build (no deploy) |
| Merge to `main` | `deploy-staging.yml` | Build + deploy to staging |
| Git tag `v*` | `deploy-production.yml` | Build + deploy to stores |

### PR Check Workflow

```yaml
# .github/workflows/pr-check.yml
name: PR Check

on:
  pull_request:
    branches: [main, develop]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Run code generation
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Analyze
        run: flutter analyze --fatal-infos

      - name: Run tests
        run: flutter test --coverage

      - name: Check formatting
        run: dart format --set-exit-if-changed .

  build-android:
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          cache: true

      - name: Build APK
        run: flutter build apk --debug --dart-define=ENVIRONMENT=dev

  build-ios:
    runs-on: macos-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          cache: true

      - name: Build iOS (no signing)
        run: flutter build ios --debug --no-codesign --dart-define=ENVIRONMENT=dev
```

### Deploy to Staging

```yaml
# .github/workflows/deploy-staging.yml
name: Deploy to Staging

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Run code generation
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Run tests
        run: flutter test

      - name: Build Android (staging)
        run: flutter build appbundle --release --dart-define-from-file=.env.staging

      - name: Deploy Cloud Functions (staging)
        uses: w9jds/firebase-action@master
        with:
          args: deploy --only functions --project tuish-food-staging
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}

      - name: Deploy Firestore rules (staging)
        uses: w9jds/firebase-action@master
        with:
          args: deploy --only firestore --project tuish-food-staging
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}

      - name: Upload to Play Store (internal track)
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT }}
          packageName: com.tuishfood.app
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal
```

### Deploy to Production

```yaml
# .github/workflows/deploy-production.yml
name: Deploy to Production

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          cache: true

      - name: Extract version from tag
        id: version
        run: echo "VERSION=${GITHUB_REF#refs/tags/v}" >> $GITHUB_OUTPUT

      - name: Install dependencies
        run: flutter pub get

      - name: Run code generation
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Run tests
        run: flutter test

      - name: Build App Bundle
        run: flutter build appbundle --release \
          --build-number=${{ github.run_number }} \
          --dart-define-from-file=.env.prod

      - name: Upload to Play Store (production)
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT }}
          packageName: com.tuishfood.app
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: production

  deploy-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Run code generation
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Build IPA
        run: flutter build ipa --release \
          --build-number=${{ github.run_number }} \
          --dart-define-from-file=.env.prod \
          --export-options-plist=ios/ExportOptions.plist

      - name: Upload to App Store Connect
        uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: build/ios/ipa/tuish_food.ipa
          issuer-id: ${{ secrets.APP_STORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APP_STORE_API_KEY_ID }}
          api-private-key: ${{ secrets.APP_STORE_API_PRIVATE_KEY }}

  deploy-firebase:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy Cloud Functions
        uses: w9jds/firebase-action@master
        with:
          args: deploy --only functions --project tuish-food-prod
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}

      - name: Deploy Firestore rules & indexes
        uses: w9jds/firebase-action@master
        with:
          args: deploy --only firestore --project tuish-food-prod
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}

      - name: Deploy Storage rules
        uses: w9jds/firebase-action@master
        with:
          args: deploy --only storage --project tuish-food-prod
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
```

---

## Version Management

### Semantic Versioning

Tuish Food follows [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH+BUILD
  |     |     |     |
  |     |     |     +-- CI build number (auto-incremented)
  |     |     +-------- Bug fixes, patches
  |     +-------------- New features (backward compatible)
  +-------------------- Breaking changes
```

**Example:** `1.2.3+45`

### Version in `pubspec.yaml`

```yaml
version: 1.2.3+45
```

### Tagging a Release

```bash
# Tag a release
git tag -a v1.2.3 -m "Release 1.2.3: Add real-time tracking improvements"
git push origin v1.2.3
```

---

## Force Update Mechanism

The `app_config/settings` document controls minimum app version:

```json
{
  "currentAppVersion": "1.3.0",
  "forceUpdateVersion": "1.2.0"
}
```

### Client-Side Check

```dart
class VersionCheckService {
  Future<VersionStatus> checkVersion() async {
    final config = await FirebaseFirestore.instance
        .doc('app_config/settings')
        .get();

    final currentAppVersion = config.data()?['currentAppVersion'] ?? '0.0.0';
    final forceUpdateVersion = config.data()?['forceUpdateVersion'] ?? '0.0.0';

    final packageInfo = await PackageInfo.fromPlatform();
    final installedVersion = packageInfo.version;

    if (_isVersionBelow(installedVersion, forceUpdateVersion)) {
      return VersionStatus.forceUpdate;
    }

    if (_isVersionBelow(installedVersion, currentAppVersion)) {
      return VersionStatus.optionalUpdate;
    }

    return VersionStatus.upToDate;
  }

  bool _isVersionBelow(String installed, String required) {
    final installedParts = installed.split('.').map(int.parse).toList();
    final requiredParts = required.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final a = i < installedParts.length ? installedParts[i] : 0;
      final b = i < requiredParts.length ? requiredParts[i] : 0;
      if (a < b) return true;
      if (a > b) return false;
    }
    return false;
  }
}

enum VersionStatus { upToDate, optionalUpdate, forceUpdate }
```

### Update Dialogs

| Status | Dialog | Dismissible |
| ------ | ------ | ----------- |
| `forceUpdate` | Full-screen "Update Required" with store link | No |
| `optionalUpdate` | Bottom banner "New version available" with "Update" and "Later" | Yes |
| `upToDate` | No dialog | -- |

---

## GitHub Secrets Required

| Secret | Purpose |
| ------ | ------- |
| `FIREBASE_TOKEN` | Firebase CLI authentication token |
| `PLAY_STORE_SERVICE_ACCOUNT` | Google Play API service account JSON |
| `APP_STORE_ISSUER_ID` | App Store Connect API issuer |
| `APP_STORE_API_KEY_ID` | App Store Connect API key ID |
| `APP_STORE_API_PRIVATE_KEY` | App Store Connect API private key |
| `KEYSTORE_BASE64` | Android release keystore (base64 encoded) |
| `KEYSTORE_PASSWORD` | Android keystore password |
| `KEY_ALIAS` | Android key alias |
| `KEY_PASSWORD` | Android key password |
