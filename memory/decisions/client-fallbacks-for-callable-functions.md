# Decision: Add client fallbacks for non-admin callable functions

**Decision:** When callable functions are unreachable (not deployed), non-admin project functions should fall back to permissive defaults/no-ops rather than blocking the user.

**Rationale:**
- The app should remain demoable without upgrading to Firebase Blaze.
- Project publishing and viewing are core user flows and should not break if Cloud Functions are unavailable.
- Admin functions cannot have safe client fallbacks because Firestore rules block direct writes; those still require deployed functions.

**Status:** Implemented in `lib/core/services/project_functions_service.dart`.
