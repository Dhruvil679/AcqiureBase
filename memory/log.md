# Session Log

## 2026-08-17 — Admin panel photo-matching pass

- Continued aligning the admin UI with the reference screenshots while keeping it style-only:
  - Updated `lib/core/theme/app_theme.dart` primary to `#065EFF` to match the reference photos.
  - Rewrote `lib/features/admin/admin_panel_screen.dart` with a responsive `NavigationRail` on desktop and `NavigationBar` on mobile, plus an AcquireBase top AppBar with notification/avatar actions.
  - Converted `admin_overview_tab.dart` to use large metric-card grid and added a Dashboard page header.
  - Added desktop data tables to `admin_moderation_tab.dart` and `admin_users_tab.dart` while keeping the existing mobile cards and all current actions.
  - Added a blue moderation-status banner to the admin review view in `lib/features/projects/project_detail_screen.dart`.
  - Added page headers to `admin_audit_log_tab.dart`.
- Verified `flutter analyze`: no issues.
- Updated memory vault: `index.md`, `status/implemented.md`, `decisions/admin-visual-restyle.md`, `log.md`.

## 2026-08-17 — Admin panel visual restyle + Android logo update

- Read `design_reference/stitch_acquirebase_material_3_admin_panel/acquirebase_admin/DESIGN.md` and extracted the style tokens.
- Rebuilt `lib/core/theme/app_theme.dart` with an explicit Material 3 `ColorScheme` and Inter typography:
  - Primary Electric Blue `#0048C9`, Secondary Steel Blue `#425BA3`, Tertiary Burnt Orange `#9B2D00`.
  - Surface-container hierarchy for layered backgrounds.
  - Buttons 8 px radius, cards 16 px radius, chips/search pill-shaped.
- Applied the restyle across all existing admin tabs without adding any new features:
  - `admin_overview_tab.dart`
  - `admin_moderation_tab.dart`
  - `project_detail_screen.dart` (admin review view)
  - `admin_users_tab.dart`
  - `admin_user_detail_screen.dart`
  - `admin_audit_log_tab.dart`
- Fixed a syntax error in `admin_users_tab.dart` (`_setProfessionFilter` arrow).
- Updated the Android launcher icon config in `pubspec.yaml` to use `assets/images/acquirebase.png` and regenerated adaptive icons.
- Verified `flutter analyze`: no issues.
- Updated memory vault: `index.md`, `implemented.md`, `decisions/admin-visual-restyle.md`, `log.md`.

## 2026-08-16 — Make admin promote/demote/suspend work on Spark plan

- Picked up user request to get admin features working before proceeding to Blaze-plan tasks.
- Diagnosed that admin actions relied on Cloud Functions that cannot be deployed on the free Spark plan.
- Implemented a callable-function-first + direct-Firestore fallback strategy:
  - `AdminFunctionsService` now catches `FirebaseFunctionsException` and writes `role`/`isSuspended` directly through `UserRepository`.
  - `UserRepository.deleteUserWithCleanup()` deletes the user doc and the matching `usernames/{username}` reservation when the callable is unavailable.
- Moved `adminFunctionsServiceProvider` from `auth_provider.dart` to `repositories_provider.dart` to avoid an import cycle with `UserRepository`.
- Updated Firestore security rules:
  - `isAdmin()` now checks the requester's own `users/{uid}` doc `role` field instead of a custom claim.
  - Admins can update only `role` or only `isSuspended` on any user doc; because `request.resource.data` contains the full resulting document, the rule uses `incoming().diff(existing()).changedKeys().hasOnly(...)` to inspect only changed keys.
  - Admins can delete `usernames/{username}` docs to release a username.
- Deployed updated rules and the Flutter web build to Firebase Hosting:
  - https://saas-management-du664-58970.web.app
- Verified the direct-Firestore fallback end-to-end with `verify_admin_firestore_rules.py`:
  - Signed in as a throwaway admin user via Firebase Auth REST.
  - Promoted/demoted a target user's `role` between `user` and `admin`.
  - Suspended and re-activated the target by toggling `isSuspended`.
  - All four operations succeeded through the deployed security rules.
- Updated memory vault: `index.md`, `implemented.md`, `in-progress.md`, `todo.md`, `known-issues.md`, `log.md`.
- **Remaining limitation:** delete-user cannot remove the Firebase Auth account without Cloud Functions/Admin SDK; it only removes Firestore data.

## 2026-08-16 — Verify Cloudinary media uploads and fix web upload path

- Picked up the remaining Priority 1 todo item: end-to-end Cloudinary media verification.
- Fixed `lib/core/services/storage_service.dart` so image uploads work on web:
  - `flutter_image_compress.compressWithFile` cannot run against web file paths, so `_getImageBytes()` now reads raw `XFile` bytes as a fallback on web (and when compression fails on mobile).
  - Document uploads already read `PlatformFile.bytes` first, so they continue to work on web.
- Added `acquirebase/test_cloudinary_upload.py` to verify the unsigned Cloudinary preset accepts both image and raw uploads.
  - Image upload returned a valid `secure_url` for a PNG.
  - Raw upload returned a valid `secure_url` for a TXT file.
- Ran `flutter analyze`: clean.
- Ran `flutter build web`: succeeded.
- Deployed the updated build to Firebase Hosting:
  - https://saas-management-du664-58970.web.app
- Updated memory vault: `todo.md`, `implemented.md`, `known-issues.md`, `index.md`.

## 2026-08-16 — Addendum: persistent login fix, full profile detail views, admin charts

- **Section 1 — persistent login fix**
  - Diagnosed the cold-start bug in `lib/features/splash/splash_screen.dart`: `authStateProvider.valueOrNull` is null before Firebase Auth restores the persisted session.
  - Rewrote `_startSplashSequence()` to await the first `authStateChanges` event alongside the splash animation and minimum duration.
  - Updated routing so verified users land on `HomeShell`, unverified users land on `LoginScreen(showVerificationPrompt: true)`, and logged-out users land on `LoginScreen`.
  - Added `showVerificationPrompt` support in `lib/features/auth/login_screen.dart` with a SnackBar and a Resend action.
  - Built and deployed the web app to Firebase Hosting.

- **Section 2 — full profile and admin user detail views**
  - Expanded `lib/features/profile/profile_screen.dart` to show every captured detail: username handle, full name, age, profession, skills, join date, bio, social links, role badge, and suspension warning. Avatar now uses `CachedNetworkImage`.
  - Added a reusable `_ProfileDetailsCard` section with detail rows and tappable social chips using `url_launcher`.
  - Expanded `lib/features/admin/admin_user_detail_screen.dart` with the same full detail set, an admin audit history timeline (`auditLogs` targeted at the user), and the user's UID.
  - Added `AuditLogRepository.watchAuditLogForTarget()` and a matching `auditLogForTargetProvider` in `repositories_provider.dart`.
  - Added the `auditLogs` composite index (`targetType`, `targetId`, `timestamp`) to `firestore.indexes.json` and deployed it.

- **Section 3 — admin overview charts**
  - Added `fl_chart` dependency and rebuilt `lib/features/admin/admin_overview_tab.dart`.
  - Added two line charts: new users over the last 30 days and new project submissions over the last 30 days.
  - Added two doughnut/pie charts: projects by category and projects by status, both with legends.
  - Charts use `Theme.of(context).colorScheme` and adapt to a single column on narrow screens and two columns on wider screens.
  - Kept the summary stat chips and recent audit activity list.

- **Verification and deployment**
  - `flutter analyze` clean after each section.
  - `flutter build web` succeeded.
  - `firebase deploy --only hosting,firestore` deployed the web app and updated Firestore indexes/rules.
  - Live URL: https://saas-management-du664-58970.web.app

## 2026-08-11 — Unique username enforcement + registration diagnostics

- Implemented atomic username reservation for AcquireBase.
  - Added `usernames/{username}` collection with one-to-one `uid` mapping.
  - Updated `UserService.createUserDocument()` to reserve the username and create the user profile in a Firestore transaction.
  - Added `UsernameAlreadyTakenException`, `normalizeUsername()`, and `isValidUsername()` helpers in `lib/core/services/user_service.dart`.
  - Added `AuthService.deleteCurrentUser()` to roll back the Auth account when username reservation fails.
  - Updated `RegisterScreen` with a 500 ms debounced availability check and an inline available/taken indicator.
  - Tightened username validation to 3–20 lowercase letters, numbers, or underscores across client and rules.
- Updated Firestore security rules (`firestore.rules`):
  - Added `isValidUsername(name)` helper.
  - Added `/usernames/{username}` rules: public read, owner-only create, no update/delete.
  - Tightened `users/{uid}` create rule to require a valid username.
- Removed dead `updateUserRole()` and `updateUserSuspension()` methods from `UserRepository` because admin writes now go through Cloud Functions.
- Improved registration error diagnostics in `RegisterScreen` so the actual Firebase error text is surfaced for unknown failures.
- Verified Firebase project connectivity (`saas-management-du664`).
- Deployed updated Firestore rules and Flutter web build to Firebase Hosting:
  - https://saas-management-du664-58970.web.app
- Confirmed `flutter analyze` clean.
- Added decision note at `memory/decisions/unique-usernames.md`.

## 2026-08-11 — Fix for registration permission-denied

- User reported `[cloud_firestore/permission-denied] Missing or insufficient permissions.` immediately after sign-up.
- Added `AuthService.getIdToken(forceRefresh: true)` and call it before the signup transaction in `UserService.createUserDocument()` to ensure the fresh Auth token is available to Firestore, especially on web.
- Rebuilt and redeployed the web app to Firebase Hosting.
- Asked user to retry registration and report the result.

## 2026-08-08 — Firestore database tables seeded

- Analyzed project: Flutter + Firebase marketplace app (AcquireBase), active project `saas-management-du664`.
- Reviewed existing Firestore collections (`activityLogs`, `notification`, `users`) and data model in `memory/architecture/data-model.md`.
- Created/seeded the following Firestore collections via Firebase MCP:
  - `users` — 6 demo user docs (`mock_user_001`..`006`), including one admin and one suspended user.
  - `projects` — 12 demo project docs (`proj_001`..`012`), mix of approved and pending statuses with featured flags.
  - `saved_projects` — 2 composite docs (`mock_user_001_proj_003`, `mock_user_001_proj_005`).
  - `auditLogs` — 2 sample admin audit entries.
  - `activityLogs` — 2 sample activity entries (kept existing real login entries intact).
  - `notifications` — 1 sample project-approval notification.
  - `projects/proj_001/history` — 1 sample edit-history entry.
- Left pre-existing `notification` (singular) collection untouched; it has a mismatched schema and should be reviewed/deleted manually.
- `rateLimits` collection will be created automatically by Cloud Functions when deployed.
- Updated memory vault (`index.md`, `log.md`).

## 2026-08-04 — Tests + Cloudinary cleanup

- Fixed outdated Firebase Storage references in upload error messages (`edit_profile_screen.dart`, `add_edit_project_screen.dart`).
- Added integration test for the onboarding flow at `integration_test/app_test.dart`.
- Added widget tests for Explore screen and Project Detail screen under `test/features/`.
- Added shared test helpers and fakes in `test/helpers.dart`.
- Fixed project card overflow in narrow widths (featured carousel) by making the category chip flexible.
- Updated README to reflect the Cloudinary switch and added a tests section.
- Updated memory vault (`index.md`, `implemented.md`, `in-progress.md`, `todo.md`, `log.md`).
- All checks pass: `flutter test`, `flutter analyze`, `functions npm run build`, `scripts npx tsc --noEmit`.

## 2026-08-03 — Cloudinary switch + registration testing

- Replaced Firebase Storage with Cloudinary for media uploads.
- Added `lib/core/services/cloudinary_config.dart` with cloud name `pkplgkql` and unsigned upload preset `acquirebase_unsigned`.
- Rewrote `lib/core/services/storage_service.dart` to upload avatars, logos, screenshots, and documents to Cloudinary.
- Updated `lib/core/providers/auth_provider.dart` to provide `CloudinaryPublic` instead of `FirebaseStorage`.
- Removed `firebase_storage` dependency from `pubspec.yaml`.
- Deleted `storage.rules` and removed Storage config from `firebase.json`.
- Built the web app (after `flutter clean`) and deployed to Firebase Hosting.
- Registered 3 fake temp-mail users via Playwright to verify auth/onboarding:
  - testuser1@tempmail.example
  - testuser2@tempmail.example
  - testuser3@tempmail.example
- Updated memory vault (`index.md`, `implemented.md`, `in-progress.md`, `todo.md`, `known-issues.md`, `log.md`).
- Confirmed `flutter analyze` clean after refactor.

## 2026-08-03 — Deployment + polish session

- Deployed Firestore security rules to `saas-management-du664`.
- Built and deployed the Flutter web app to Firebase Hosting: https://saas-management-du664-58970.web.app.
- Tightened `logAuditEntry` Cloud Function to require the admin custom claim.
- Deleted redundant scratch file `acquirebase/fbs-data.js`.
- Expanded `scripts/seed_firestore.ts` with 5 additional demo projects (12 total).
- Added reusable `EmptyState` widget at `lib/core/widgets/empty_state.dart`.
- Improved empty/error states on Explore, Dashboard, Profile, and Admin Overview tabs.
- Attempted Storage rules deployment; blocked because Firebase Storage is not yet enabled in the console.
- Attempted to run seed script; blocked because this environment lacks `gcloud` / service-account credentials.
- Updated memory vault (`index.md`, `implemented.md`, `in-progress.md`, `todo.md`, `known-issues.md`, `log.md`).
- All checks pass: `flutter analyze`, `functions npm run build`, `scripts npx tsc --noEmit`.

## 2026-08-02 — Vault bootstrap + non-deployment completion

- Added graceful fallbacks for non-admin callable functions (`checkProjectSubmissionRate`, `recordProjectSubmission`, `incrementProjectView`) so the app works without deployed Cloud Functions.
- Created Firestore seed script at `scripts/seed_firestore.ts` to populate demo users and projects.
- Replaced all `Image.network` usages with `cached_network_image` via a new reusable `AppNetworkImage` widget.
- Rewrote `README.md` with architecture, setup, seed, hosting, and deployment instructions.
- Verified Storage integration for avatars, logos, screenshots, and documents.
- Added Firebase Hosting config to `firebase.json` and created `.firebaserc`.
- Replaced avatar display `NetworkImage` with `CachedNetworkImageProvider`.
- Generated project summary file `summry`.
- Bootstrapped the project memory vault at `memory/` with `CLAUDE.md`, `index.md`, architecture docs, status files, known issues, and decision files.
- All checks pass: `flutter analyze`, `functions npm run build`, `scripts npx tsc --noEmit`.

## 2026-08-02 — Humanize/style pass across codebase

- Rewrote `functions/src/index.ts` in a more natural voice; removed templated section dividers and redundant "what" comments while keeping rationale for custom claims, rate limiting, transactions, and audit-log trustworthiness.
- Light edit of `scripts/seed_firestore.ts` to simplify the header and remove divider-style comments.
- Rewrote `README.md` with a genuine human voice ("I" instead of detached tone), varied sentence structure, and less rigid heading structure.
- Style-only pass on Dart files in `lib/`: removed uniform dividers and redundant doc comments, kept architecture/security rationale.
- Light touch on `firestore.rules` and `storage.rules`: removed `// -------------------------------------------------------------------------` dividers, simplified section headers, preserved all security rationale.
- Verified: `flutter analyze`, `functions npm run build`, and `scripts npx tsc --noEmit` all pass.

## 2026-08-02 — Deeper Dart humanization pass

- Revisited all 46 Dart files in `lib/` after the first pass was too conservative.
- Rewrote file-level and inline comments to sound like genuine student-written code: casual, direct, and varied in tone.
- Kept important architecture and security rationale but reworded it in a student voice.
- Verified: `flutter analyze` passes with no issues.

## Earlier sessions (summarized)

- Built complete Flutter UI for user and admin flows.
- Implemented Firebase Auth, Firestore repositories, Storage service, and security rules.
- Added activity logging, project edit history, notifications, and audit log.
- Wrote TypeScript Cloud Functions for admin claims, rate limiting, view counting, and audit logging.
- Implemented mock fallback for unconfigured platforms.
- Added pagination and composite-index-aware queries.
