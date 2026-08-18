<<<<<<< HEAD
# AcquireBase

This is a Flutter marketplace app I built for discovering and publishing digital products — startups, SaaS tools, AI apps, mobile apps, that sort of thing. Think of it as a small Product Hunt-style demo.

I built it as a college project, so the backend is Firebase-shaped: Auth, Firestore, Cloud Functions, and App Check. Media uploads go to Cloudinary. It compiles and runs locally without a paid Firebase plan, although a couple of admin features need Cloud Functions deployed to work end-to-end.

---

## What it does

Users can:

- Browse approved projects by category, or check out the featured carousel.
- Search for projects by name or tagline.
- Save projects they like.
- Publish their own projects, complete with a logo, screenshots, documents, and founder details.
- Manage their profile, avatar, bio, and social links.

Admins can:

- Review pending submissions (approve, reject, feature, remove, restore).
- Manage users (suspend, activate, promote, demote, delete).
- View an audit log of admin actions and export it as CSV.

There's also an email-verification gate before publishing, activity logging, project edit history, and notifications when a project's status changes.

---

## What I used

- **Flutter 3.x** with Dart
- **flutter_riverpod** for state management
- **Firebase**
  - Authentication (email/password)
  - Cloud Firestore
  - Cloud Functions (TypeScript, v2)
  - App Check (Android Play Integrity — optional)
- **Cloudinary** for media uploads (avatars, logos, screenshots, documents)

---

## Folder layout

```
acquirebase/
├── lib/
│   ├── core/
│   │   ├── models/           # Data classes
│   │   ├── providers/        # Riverpod providers
│   │   ├── services/         # Repositories and backend services
│   │   ├── theme/            # AppTheme (Material 3, GoogleSans)
│   │   ├── utils/            # Helpers and formatters
│   │   └── widgets/          # Shared widgets
│   ├── features/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── explore/
│   │   ├── saved/
│   │   ├── profile/
│   │   ├── projects/
│   │   └── admin/
│   ├── firebase_options.dart
│   └── main.dart
├── functions/                # Cloud Functions (TypeScript)
├── scripts/                  # Admin scripts, including the Firestore seed
├── .firebaserc
├── firestore.rules
├── firestore.indexes.json
├── firebase.json
└── memory/                   # Project memory vault
```

---

## Getting started

### Prerequisites

You'll need Flutter (^3.11.4), Node.js 20+, and the Firebase CLI:

```bash
npm install -g firebase-tools
```

### Install dependencies

```bash
cd acquirebase
flutter pub get

cd functions
npm install

cd ../scripts
npm install
```

### Firebase setup

The project is already configured for Android and Web in `lib/firebase_options.dart` and `firebase.json`. For Android, drop your `google-services.json` into:

```
acquirebase/android/app/google-services.json
```

I didn't set up iOS for this project, but if you want it, register the app in the Firebase console and run:

```bash
flutterfire configure
```

### Cloudinary setup

Media uploads (avatars, logos, screenshots, documents) use Cloudinary instead of Firebase Storage. The credentials live in `lib/core/services/cloudinary_config.dart`:

```dart
static const String cloudName = 'your_cloud_name';
static const String uploadPreset = 'your_unsigned_preset';
```

Create an unsigned upload preset in your Cloudinary console:
**Settings → Upload → Upload presets → Add upload preset → Signing: Unsigned**.
Make sure the preset allows both images and raw files if you want document uploads to work.

### Deploy Firestore rules

```bash
firebase deploy --only firestore:rules
```

### Run the app

```bash
flutter run
```

On iOS, Windows, Linux, and macOS the app falls back to in-memory mock data, so the UI is still demoable even without Firebase configured.

---

## Seed some demo data

To populate Firestore with the demo users and projects:

```bash
cd scripts
npm run seed
```

See `scripts/README.md` for authentication options — `gcloud auth application-default login` is usually the easiest.

---

## Hosting the web version

I added Firebase Hosting config to `firebase.json`. To deploy:

```bash
flutter build web
firebase deploy --only hosting
```

The hosting site is `saas-management-du664-58970`.

---

## What works without paying for Firebase

Most of the app runs fine on the Spark plan:

- Authentication, Firestore reads/writes, and Cloudinary media uploads.
- Publishing, saving, and browsing projects after seeding data.
- Non-admin callable functions fall back gracefully when Cloud Functions aren't deployed, so project publishing and viewing still work.

## What needs the Blaze plan

These features rely on deployed Cloud Functions:

- Admin user actions: promote/demote, suspend/activate, delete user.
- Server-side project submission rate-limiting.
- Server-side view counting with a per-user cooldown.
- App Check with Play Integrity (optional but recommended).

To deploy functions after upgrading:

```bash
cd functions
npm run build
firebase deploy --only functions
```

---

## Security rules

I wrote Firestore rules to enforce ownership and admin boundaries. You can find them in:

- `firestore.rules`

Deploy them with:

```bash
firebase deploy --only firestore:rules
```

---

## Running tests

```bash
# Widget + integration tests (headless)
flutter test

# Integration tests on a device/emulator
flutter test integration_test/app_test.dart
```

The tests use fakes and provider overrides so they don't need a Firebase backend.

## Composite indexes

Some paginated queries need composite indexes. If you hit an index error, create these in the Firebase Console:

- `projects`: `status` ascending, `createdAt` descending
- `projects`: `category` ascending, `status` ascending, `createdAt` descending
- `projects`: `ownerId` ascending, `createdAt` descending

---

## A note on scope

This is a college/demo project, so I intentionally kept some things simple: client-side search, no dedicated error-tracking service, and no production-scale search backend. For a real launch you'd probably want Algolia, proper logging, more integration tests, and a stricter rules review.
=======
# AcqiureBase
>>>>>>> 5b67c2c37bb659ac6604ed1acd20af16f0fa0a60
