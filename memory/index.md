# AcquireBase — Current State

**Project:** AcquireBase  
**Location:** `D:\Marketplace\acquirebase`  
**Type:** Flutter mobile marketplace for digital products (startups, SaaS, AI tools, etc.)  
**Purpose:** College / demo project with Firebase backend  
**Last updated:** 2026-08-17

---

## One-line summary

A Flutter + Firebase marketplace app with user/auth, project discovery/saving/publishing, admin moderation, and Cloudinary-hosted media. It runs on the free Firebase Spark plan; Cloud Functions are written but not deployed.

---

## What's working now

- Full UI for user and admin flows, now restyled to the AcquireBase admin panel reference.
- Android launcher icon updated to `assets/images/acquirebase.png` with adaptive-icon support.
- Material 3 admin theme rebuilt with explicit design tokens: Inter font, Primary Electric Blue `#065EFF`, Secondary Steel Blue `#425BA3`, Tertiary Burnt Orange `#9B2D00`, and surface-container hierarchy. Buttons use 8 px radius, cards 16 px, and search/filter chips are pill-shaped.
- Admin panel restyled across Overview, Moderation, Project detail review, Users, User detail, and Audit Log tabs. No new admin features were added.
- Admin shell is now responsive: `NavigationRail` on desktop, `NavigationBar` on mobile, plus a top AppBar with notification/avatar actions.
- Admin Overview uses large metric-card grid; Moderation and Users use data tables on desktop and cards on mobile.
- Admin project review shows a blue status banner for the current moderation state.
- Firebase Auth (register, login, forgot password, email verification) with persistent session routing.
- Splash screen waits for the restored Firebase Auth state; verified users go straight to the home shell.
- Unique, immutable username reservation at signup via the `usernames/{username}` collection and a Firestore transaction.
- Firestore-backed repositories with mock fallback for unconfigured platforms.
- Project publishing with logo, screenshots, and documents (uploaded to Cloudinary).
- Full user profiles (own profile and admin user detail) showing every captured field: name, username, age, profession, skills, bio, social links, role, suspension state, join date, and admin audit history.
- Social link chips launch Twitter, LinkedIn, and website URLs via `url_launcher`.
- Explore, search, save/unsave, featured carousel, category filters.
- Admin panel: overview with `fl_chart` line and pie charts, moderation, user management, audit log, CSV export.
- Admin overview charts: new users over time, new project submissions over time, projects by category, projects by status.
- Admin promote/demote and suspend/activate now work via a callable-function-first + direct-Firestore fallback (Spark plan).
- Activity logging and project edit history.
- Firestore security rules deployed.
- Media uploads handled by Cloudinary (`cloudinary_public`) instead of Firebase Storage.
- Cloudinary unsigned upload preset verified for images and raw documents; web uploads now fall back to raw bytes when compression is unavailable.
- Cloud Functions written and compiling (not deployed).
- Dart callable-function services wired; non-admin functions gracefully fall back when not deployed.
- Firestore seeded with demo users, projects, saved_projects, auditLogs, activityLogs, notifications, and sample project history via Firebase MCP.
- Firestore seed script available as `scripts/seed_firestore.ts` for re-seeding from Node.js.
- `cached_network_image` used throughout.
- Firebase Hosting config committed and deployed at https://saas-management-du664-58970.web.app.
- `flutter analyze` clean.
- Cloud Function `logAuditEntry` tightened to require admin claim.
- Redundant scratch file `fbs-data.js` removed.
- Reusable `EmptyState` widget; improved empty/error states on Explore, Dashboard, Profile, and Admin Overview.
- Widget and integration tests for onboarding, Explore, and Project Detail flows.
- Project card layout fixed to avoid overflow in narrow widths (featured carousel).

---

## What's pending / blocked

| Item | Blocker | Notes |
|------|---------|-------|
| Cloud Functions deployment | Blaze plan required | Firebase Spark does not allow Cloud Functions. Upgrade to Blaze, then `cd functions && npm run build && firebase deploy --only functions`. |
| Full admin delete-user (Auth account removal) | Blaze plan | Client-side fallback removes the Firestore user doc and username reservation, but cannot delete another user's Firebase Auth account without Admin SDK / deployed function. |
| Rate limiting / view counting | Blaze plan | Needs deployed Cloud Functions. |
| Play Integrity | Console setup | Optional; App Check fails gracefully. |
| iOS support | Intentionally skipped | Only Android + Web are configured. |

---

## Tech stack

- Flutter 3.x / Dart
- flutter_riverpod
- Firebase Auth, Firestore, Cloud Functions, App Check
- Cloudinary (media uploads)
- TypeScript Cloud Functions (v2)

---

## Quick commands

```bash
flutter pub get

cd functions && npm install
cd ../scripts && npm install

flutter run

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy web hosting
flutter build web
firebase deploy --only hosting

# Deploy functions (requires Blaze)
cd functions && npm run build && firebase deploy --only functions
```

---

## Key files

- `lib/main.dart` — app entry point
- `lib/core/services/storage_service.dart` — Cloudinary media uploads
- `lib/core/services/cloudinary_config.dart` — Cloudinary credentials
- `lib/core/services/project_functions_service.dart` — callable fallbacks
- `lib/firebase_options.dart` — Android + Web config
- `firebase.json` — Hosting, functions, Firestore config
- `firestore.rules` — security rules
- `scripts/seed_firestore.ts` — demo data seed
- `memory/CLAUDE.md` — how to maintain this vault

---

## Drill-down files

- Architecture: `architecture/overview.md`, `architecture/data-model.md`, `architecture/security.md`
- Status: `status/implemented.md`, `status/in-progress.md`, `status/todo.md`
- Decisions: `decisions/`
- Known issues: `issues/known-issues.md`
- Session log: `log.md`
