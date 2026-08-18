# Decision: Use mock fallback when Firebase is unavailable

**Decision:** When `Firebase.apps.isEmpty` (unconfigured platform or failed initialization), repositories fall back to in-memory mock data from `MockDataService`.

**Rationale:**
- Allows UI development and demos without a configured Firebase backend.
- Keeps the app runnable on iOS, Windows, Linux, and macOS, which are not configured for Firebase.
- No conditional UI logic needed; repositories handle the fallback transparently.

**Status:** Implemented in all repository classes.
