# AcquireBase — Completed Features Overview

> Last updated: 2026-07-30
>
> This document summarizes what has been implemented and is functional in the AcquireBase Flutter project as of the date above.

---

## Project Identity

- **Display name:** AcquireBase
- **Package name (pubspec):** `acquirebase`
- **Location:** `D:\Marketplace\acquirebase`
- **Framework:** Flutter SDK `^3.11.4`
- **Design system:** Material 3 with custom GoogleSans font family
- **State management:** `flutter_riverpod` 2.6.1

AcquireBase is a mobile marketplace application for discovering, saving, and publishing digital products such as startups, SaaS tools, AI apps, and other builder projects.

---

## Architecture & Folder Structure

The project follows a feature-first structure under `lib/`:

```
lib/
├── main.dart                          # App entry point
├── firebase_options.dart              # Firebase configuration (Android configured)
├── core/
│   ├── theme/app_theme.dart           # Light & dark Material 3 themes
│   ├── models/                        # Data models
│   │   ├── user_model.dart            # User profile, profession, social links
│   │   ├── project_model.dart         # Project listing, categories, status
│   │   └── audit_log_entry.dart       # Admin audit log row
│   ├── providers/
│   │   └── auth_provider.dart         # Riverpod auth/firebase providers
│   ├── services/
│   │   ├── auth_service.dart          # Firebase Auth wrapper
│   │   ├── user_service.dart          # Firestore user document helper
│   │   └── mock_data_service.dart     # In-memory backend (currently active)
│   └── router/home_shell.dart         # Bottom navigation shell
└── features/
    ├── splash/splash_screen.dart
    ├── onboarding/onboarding_screen.dart
    ├── auth/login_screen.dart
    ├── auth/register_screen.dart
    ├── explore/explore_screen.dart
    ├── saved/saved_screen.dart
    ├── dashboard/dashboard_screen.dart
    ├── profile/profile_screen.dart
    ├── profile/edit_profile_screen.dart
    ├── projects/project_detail_screen.dart
    ├── projects/add_edit_project_screen.dart
    ├── projects/widgets/project_card.dart
    └── admin/
        ├── admin_panel_screen.dart
        ├── admin_overview_tab.dart
        ├── admin_moderation_tab.dart
        ├── admin_users_tab.dart
        ├── admin_user_detail_screen.dart
        └── admin_audit_log_tab.dart
```

---

## Latest Completed Work

### Area 1 — Quick wins (completed)

- **External links now work.** Added `url_launcher` and wired:
  - "Visit website" button on `project_detail_screen.dart`.
  - Document links in the project detail "Documents" section.
  - Safe fallback snackbar for invalid/unlaunchable URLs.
- **Save/bookmark button added to `ProjectCard`.**
  - Appears in Explore feed and featured carousel.
  - Visible in Saved screen with remove action.
  - Not shown for own projects on Profile or admin views.
- **Mock save persistence fixed.** `MockDataService.toggleSavedProject` now updates `currentUser.savedProjectIds` correctly, and `currentUser` is no longer `final` so it can be reassigned with updated state.
- **Package name normalized.** `pubspec.yaml` changed from `Ewwww_bhatii` to `acquirebase`; Android `applicationId` remains `com.example.project_screen`.
- **Static analysis clean.** `flutter analyze` reports **No issues found** after Area 1.

### Area 2 — Security foundation (partially deployed)

- **Firebase project target fixed.** `firebase.json` now points to `saas-management-du664`, matching `firebase_options.dart` and `android/app/google-services.json`.
- **Firestore security rules written and deployed.** See `firestore.rules`.
- **Storage security rules written.** See `storage.rules`. Not yet deployed because Firebase Storage is not initialized in the console.
- **Cloud Functions written and building.** See `functions/src/index.ts`. Functions compile with `npm run build`. Not yet deployed because the project must be upgraded to the Blaze plan.
- **App Check code added.** `main.dart` activates Play Integrity provider; console enrollment still required.
- **Functions included:**
  - `setAdminClaim` — promotes/demotes admins via Auth custom claims + Firestore role mirror.
  - `checkProjectSubmissionRate` / `recordProjectSubmission` — enforces 5 project submissions per 24h window.
  - `incrementProjectView` — rate-limited view count increment (one per user per project per hour).
  - `deleteUserAccount` — admin-only deletion of Auth + Firestore user doc.
  - `logAuditEntry` — admin-only audit log writer.

### Area 3 — Real Authentication (completed)

- **Login screen wired to Firebase Auth.** Calls `AuthService.signIn`, shows friendly error messages, includes "Forgot password?" flow.
- **Register screen wired to Firebase Auth + Firestore.** Creates Auth account, then calls `UserService.createUserDocument` with username, first/last name, age, skills, profession. Sends email verification after sign-up.
- **Email verification gate.** New project submissions in `add_edit_project_screen.dart` block until the current user's email is verified; offers a resend link.
- **Splash screen uses real auth state.** Now watches `authStateProvider` instead of directly checking `FirebaseAuth.instance.currentUser`.
- **AuthService expanded.** Added `sendPasswordResetEmail`, `sendEmailVerification`, and `reloadCurrentUser`.

---

## Completed Features

### 1. Application Shell & Navigation

- **Animated splash screen** (`splash_screen.dart`)
  - Logo scale/opacity/slide/tagline animations.
  - 2.5 second minimum splash duration.
  - Routes to onboarding, login, or home based on `SharedPreferences` and Firebase Auth state.

- **Onboarding flow** (`onboarding_screen.dart`)
  - 3-slide onboarding: Discover → Save → Publish.
  - Skip button and page indicators.
  - Persists `has_seen_onboarding` flag in `SharedPreferences`.

- **Bottom navigation shell** (`home_shell.dart`)
  - 4 tabs: Explore, Saved, Dashboard, Profile.
  - Uses `IndexedStack` to preserve scroll state and tab state.

### 2. Authentication Screens

- **Login screen** (`login_screen.dart`)
  - Email and password form with validation.
  - Password visibility toggle.
  - Loading state and navigation to home shell.

- **Register screen** (`register_screen.dart`)
  - Account section: email, password, confirm password.
  - Profile section: first name, surname, age.
  - Profession dropdown.
  - Skills selector with starter chips and custom skill input/removal.
  - Validation and welcome feedback.

> Note: Auth UI is complete; the actual Firebase Auth integration is prepared via `AuthService` but not yet wired into the UI.

### 3. Theme & Branding

- **Material 3 theme** (`core/theme/app_theme.dart`)
  - Seed color `#0060E0`.
  - Light and dark variants.
  - Rounded buttons (stadium), cards (12px), inputs (12px), FABs (16px).
  - Custom GoogleSans typography applied globally.

- **Assets**
  - App icon: `assets/images/acquirebase_icon.png`
  - Full logo: `assets/images/acquirebase_full_logo.png`
  - GoogleSans font family loaded from `assets/static/`
  - Launcher icon generation configured in `pubspec.yaml`

### 4. Explore Feed

- **Explore screen** (`explore_screen.dart`)
  - Search bar with live filtering.
  - Horizontal category filter chips (All + all `ProjectCategory` values).
  - Featured project carousel when no search/category is active.
  - Discover list of approved projects using `ProjectCard`.
  - Floating action button to add a new project.

### 5. Project Discovery & Management

- **Project card** (`projects/widgets/project_card.dart`)
  - Logo placeholder or network image.
  - Name, tagline, category chip, save count.
  - Tap handling for navigation.
  - Featured variant used in carousel.

- **Project detail screen** (`projects/project_detail_screen.dart`)
  - Header with logo, name, tagline, category.
  - Founder info section.
  - Business age, monthly visitors, save count info cards.
  - Description section.
  - Screenshot gallery (horizontal scroll).
  - Document list.
  - Owner actions: edit, delete.
  - Save/unsave action.
  - Admin actions (when `adminView = true`): approve, reject, re-approve, feature, unfeature, remove, restore — all with reason dialogs where appropriate.

- **Add / Edit project screen** (`projects/add_edit_project_screen.dart`)
  - Project details: name, tagline, description, category dropdown, website URL.
  - Business details: business age, monthly visitors.
  - Founder details: name, bio (auto-filled from current user).
  - Media: screenshot URLs and document URLs list editors.
  - Validation on required fields.
  - New submissions default to `pending` status.

### 6. Saved Projects

- **Saved screen** (`saved_screen.dart`)
  - Lists projects saved by the current user.
  - Swipe-to-remove with undo snackbar.
  - Empty state illustration.

### 7. Dashboard

- **Dashboard screen** (`dashboard_screen.dart`)
  - Overview stat cards: Projects, Views, Saves.
  - List of current user’s projects.
  - Quick edit and delete actions.
  - Floating action button to add a project.
  - Delete confirmation dialog.

### 8. Profile

- **Profile screen** (`profile_screen.dart`)
  - Avatar with initials fallback.
  - Display name, email, bio.
  - Published project count and profile view count.
  - Admin panel button (visible for `role == 'admin'`).
  - List of own projects.
  - Log out button.

- **Edit profile screen** (`edit_profile_screen.dart`)
  - Display name and bio editing.
  - Social links: Twitter/X, LinkedIn, Website.
  - Avatar picker (mock URL toggle for now).
  - Form validation and save feedback.

### 9. Admin Panel

- **Admin panel screen** (`admin_panel_screen.dart`)
  - 4-tab layout: Overview, Moderation, Users, Audit Log.

- **Overview tab** (`admin_overview_tab.dart`)
  - Platform stats: total users, total projects, pending/approved/rejected counts, featured count, active users, suspended users.
  - Category breakdown bar chart.
  - Recent audit activity list.

- **Moderation tab** (`admin_moderation_tab.dart`)
  - Search projects.
  - Status filter chips: all, pending, approved, rejected, removed.
  - Category dropdown filter.
  - Moderation cards with context-aware actions.
  - Direct approve/reject/feature/remove/restore buttons per card.

- **Users tab** (`admin_users_tab.dart`)
  - Search by name, email, or username.
  - Role filter and status filter dropdowns.
  - User cards showing avatar, name, email, role, suspension status.

- **User detail screen** (`admin_user_detail_screen.dart`)
  - Full profile view.
  - Info grid: username, email, profession, age.
  - Suspend / activate account.
  - Promote / demote admin role.
  - Delete account with confirmation.
  - List of user’s published projects.

- **Audit log tab** (`admin_audit_log_tab.dart`)
  - Reverse-chronological list of admin actions.
  - Target type icons and reason display.
  - Pull-to-refresh scaffold.

### 10. Data Models & Mock Backend

- **User model** (`core/models/user_model.dart`)
  - Fields: uid, username, email, name, age, skills, profession, photoUrl, bio, social links, role, suspension, timestamps, profile views, published/saved IDs.
  - `Profession` enum with labels.
  - `SocialLinks` value object.

- **Project model** (`core/models/project_model.dart`)
  - Fields: projectId, ownerId, name, logoUrl, tagline, description, category, websiteUrl, businessAge, monthlyVisitors, screenshotUrls, documentUrls, founder info, status, featured flag, timestamps, save/view counts.
  - `ProjectCategory` enum with labels.

- **Audit log model** (`core/models/audit_log_entry.dart`)
  - Tracks admin actions with timestamp, admin, target, action, and optional reason.

- **Mock data service** (`core/services/mock_data_service.dart`)
  - Pre-populated users, projects, and audit log entries.
  - Provides query helpers: approved/pending/featured/search/category/user/saved projects.
  - User management helpers: suspend, activate, promote, demote, delete.
  - Project moderation helpers: approve, reject, reapprove, feature, unfeature, remove, restore.
  - Audit logging helper.

### 11. Firebase Foundation

- Firebase packages added to `pubspec.yaml`.
- `firebase_options.dart` generated for Android.
- `main.dart` initializes Firebase with platform-specific options.
- Unsupported platforms are caught gracefully so the app does not crash on web/desktop.
- `AuthService` and `UserService` exist as the intended backend contract.

---

## Known Gaps (Not Yet Implemented)

The following are intentionally deferred and marked with inline `// ... later` comments:

- Real Firebase Auth wiring in login/register.
- Real Firestore reads/writes for users, projects, saved projects, and audit log.
- Real Firebase Storage image upload for avatars and project media.
- Platform support beyond Android in `firebase_options.dart`.

---

## How to Run

```bash
cd D:\Marketplace\acquirebase
flutter pub get
flutter run
```

The app will launch in mock mode and all screens above are navigable without a real backend.

---

## Next Recommended Milestones

1. **Quick wins:** add `url_launcher`, wire external links, add save button to project cards, fix mock save persistence.
2. **Media upload:** wire `image_picker` + `flutter_image_compress` + `firebase_storage` for avatars and project images.
3. **Backend integration:** replace mock service calls with Firestore repositories.
4. **Auth integration:** connect login/register to Firebase Auth and create user documents.
5. **Polish:** package rename, static analysis cleanup, platform expansion.
