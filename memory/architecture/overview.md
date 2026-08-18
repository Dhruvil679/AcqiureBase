# Architecture Overview

## High-level design

AcquireBase is a standard Flutter client app backed by Firebase services. The client owns the UI and state management; Firebase handles auth, database, file storage, and optional server-side logic.

```
┌─────────────────────────────────────┐
│  Flutter App (Android + Web)        │
│  - Material 3 UI                    │
│  - Riverpod state management        │
│  - Repository pattern               │
└──────────────┬──────────────────────┘
               │
    ┌──────────┼──────────┐
    ▼          ▼          ▼
┌────────┐ ┌────────┐ ┌───────────┐
│  Auth  │ │Firestore│ │  Storage  │
└────────┘ └────────┘ └───────────┘
    │          │            │
    ▼          ▼            ▼
┌─────────────────────────────────────┐
│  Cloud Functions (optional)         │
│  - Admin claims                     │
│  - Rate limiting                    │
│  - View counting                    │
└─────────────────────────────────────┘
```

## Folder structure

```
lib/
├── core/
│   ├── models/           # Immutable data classes
│   ├── providers/        # Riverpod providers
│   ├── services/         # Repositories + backend services
│   ├── theme/            # AppTheme
│   ├── utils/            # Helpers
│   └── widgets/          # Shared widgets
└── features/
    ├── auth/             # Login/register/forgot password
    ├── dashboard/        # User stats + projects
    ├── explore/          # Public project feed
    ├── saved/            # Saved projects
    ├── profile/          # Profile + edit + notifications
    ├── projects/         # Detail + add/edit
    └── admin/            # Admin panel tabs
```

## State management

- **Riverpod** is used throughout.
- Repositories are provided as singletons.
- Streams (`StreamProvider`) drive live UI updates for projects, users, saved IDs, activity, audit logs, and notifications.
- `StateProvider` / `StateNotifier` patterns are avoided; the app uses `Future`/`Stream` providers plus local `StatefulWidget` state for forms.

## Backend services

| Service | Responsibility |
|---------|---------------|
| `AuthService` | Firebase Auth wrapper |
| `UserService` | Creates user doc after sign-up |
| `ProjectRepository` | Project CRUD, search, moderation, history |
| `SavedProjectRepository` | Save/unsave composite docs |
| `UserRepository` | Profile reads/writes, admin user ops |
| `AuditLogRepository` | Admin audit log |
| `ActivityLogRepository` | User activity feed |
| `NotificationRepository` | Project status notifications |
| `StorageService` | Avatar/logo/screenshot/document uploads |
| `AdminFunctionsService` | Callable: setAdminClaim, setUserSuspension, deleteUserAccount |
| `ProjectFunctionsService` | Callable: rate-limit check, record submission, increment view |

## Mock fallback

When `Firebase.apps.isEmpty` (web/desktop without config, or any platform where init fails), repositories return in-memory mock data from `MockDataService`. This keeps the UI demoable without a backend.

## Build targets

- Primary: Android
- Secondary: Web (for Firebase Hosting demo)
- iOS / Windows / Linux / macOS: not configured for Firebase; falls back to mock data
