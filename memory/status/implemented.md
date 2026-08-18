# Implemented

## UI / UX
- [x] Complete user-facing flow (explore, search, saved, profile, dashboard)
- [x] Complete admin flow (overview, moderation, users, audit log) — restyled with explicit Material 3 tokens
- [x] Material 3 theme with Inter font and design-system color tokens (Primary Electric Blue `#065EFF`, Secondary Steel Blue `#425BA3`, Tertiary Burnt Orange `#9B2D00`)
- [x] Light/dark theme support
- [x] Android adaptive launcher icon using `assets/images/acquirebase.png`
- [x] Responsive/constrained layouts for tablets/desktop web
- [x] Persistent login: splash screen waits for Firebase Auth state before routing
- [x] Full user profile view with all captured details and social links
- [x] Admin user detail view with role/suspension state and audit history
- [x] Admin overview with `fl_chart` graphs (users over time, projects over time, category/status breakdown)
- [x] Responsive admin shell with `NavigationRail` (desktop) and `NavigationBar` (mobile) plus top AppBar
- [x] Admin Overview with large metric-card grid
- [x] Admin Moderation with desktop data table and mobile cards
- [x] Admin Users with desktop data table and mobile cards
- [x] Admin project review with blue moderation-status banner

## Authentication
- [x] Firebase Auth email/password registration
- [x] Login
- [x] Forgot password
- [x] Email verification gate before publishing
- [x] Unique username enforcement with `usernames/{username}` collection and Firestore transaction
- [x] Debounced username availability indicator on registration screen
- [x] Rollback of Auth account if username reservation fails

## Data layer
- [x] Firestore-backed repositories with mock fallback
- [x] ProjectRepository (CRUD, search, moderation, history)
- [x] SavedProjectRepository (composite IDs)
- [x] UserRepository (profile, admin ops)
- [x] AuditLogRepository
- [x] ActivityLogRepository
- [x] NotificationRepository

## Features
- [x] Browse approved projects
- [x] Featured carousel (capped at 20)
- [x] Category filters
- [x] Search projects client-side
- [x] Save/unsave projects
- [x] Publish project with media
- [x] Edit project with history tracking
- [x] User profile editing (name, bio, avatar, social links)
- [x] Admin moderation (approve, reject, feature, remove, restore)
- [x] Admin user management UI
- [x] Admin promote/demote and suspend/activate work on Spark plan (callable + Firestore fallback)
- [x] Audit log with CSV export
- [x] Notifications for project status changes
- [x] Activity feed on dashboard and admin user detail

## Media
- [x] StorageService with image compression
- [x] Cloudinary integration for image and document uploads
- [x] Cloudinary preset end-to-end verification for images and raw files
- [x] Avatar upload to Cloudinary
- [x] Project logo upload to Cloudinary
- [x] Project screenshot upload to Cloudinary
- [x] Project document upload (PDF/DOC/DOCX/TXT) to Cloudinary
- [x] `cloudinary_public` package configured with unsigned upload preset
- [x] cached_network_image used throughout
- [x] AppNetworkImage reusable widget
- [x] User-facing upload error messages reference Cloudinary (not Firebase Storage)

## Backend code
- [x] Firestore security rules
- [x] Firestore security rules deployed
- [x] `usernames/{username}` rules for unique, immutable handles
- [x] Cloud Functions written and compiling (TypeScript v2)
- [x] Cloud Function `logAuditEntry` requires admin claim
- [x] Dart callable-function services
- [x] Graceful fallbacks for non-admin callable functions
- [x] Admin promote/demote/suspend fallback to direct Firestore writes when Cloud Functions are unavailable
- [x] Firestore seeded with demo data via Firebase MCP (users, projects, saved_projects, auditLogs, activityLogs, notifications, project history)
- [x] Firebase Hosting config in firebase.json
- [x] Firebase Hosting deployed

## Quality
- [x] flutter analyze clean
- [x] Functions TypeScript compiles
- [x] Seed script TypeScript compiles
- [x] README with setup/deployment/seed/hosting docs
- [x] Memory vault initialized
- [x] Redundant scratch file `fbs-data.js` removed
- [x] Reusable `EmptyState` widget
- [x] Polished empty/error states on Explore, Dashboard, Profile, Admin Overview, Moderation, Users, User detail, and Audit Log
- [x] Admin panel visual restyle applied consistently across all admin tabs (cards, buttons, chips, search, typography)
- [x] Web app registration tested with 3 fake temp-mail users via Playwright
- [x] Integration test for onboarding flow
- [x] Widget tests for Explore feed, category filter, search, and project detail
- [x] Project card layout fixed to avoid overflow in narrow widths
