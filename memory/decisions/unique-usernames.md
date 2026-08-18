# Unique, Immutable Usernames

## Decision
Usernames in AcquireBase are unique, case-insensitive, immutable, and reserved atomically at registration.

- A top-level `usernames/{username}` collection maps each normalized username to its owner's `uid`.
- The normalized form is the username trimmed and lowercased.
- Valid usernames are 3–20 characters and match `^[a-z0-9_]+$`.
- During sign-up, the `usernames/{username}` doc and the `users/{uid}` doc are written in a single Firestore transaction.
- The register screen shows a debounced (500 ms) availability indicator, but the transaction is the real enforcement.
- If username reservation fails after the Firebase Auth account is created, the Auth user is deleted so the user can retry with a different username.
- Clients can never update or delete a `usernames/{username}` doc; usernames never change.

## Rationale
This prevents duplicate usernames and race conditions without relying on eventually consistent queries. It also gives users stable `@username` handles for profiles and sharing.

## Files involved
- `lib/core/services/user_service.dart` — `UsernameAlreadyTakenException`, `normalizeUsername`, `isValidUsername`, `isUsernameAvailable`, transactional `createUserDocument`.
- `lib/core/services/auth_service.dart` — `deleteCurrentUser()` for rollback.
- `lib/features/auth/register_screen.dart` — debounced availability check and inline indicator.
- `firestore.rules` — `isValidUsername()` helper and `/usernames/{username}` rules.
