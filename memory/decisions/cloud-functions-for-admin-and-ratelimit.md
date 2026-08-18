# Decision: Use Cloud Functions for admin actions and rate limiting

**Decision:** Implement admin operations (promote/demote, suspend/activate, delete user) and server-side counters (submission rate limit, view count) as Firebase callable Cloud Functions.

**Rationale:**
- Firestore security rules cannot trust the client with sensitive fields like `role` and `isSuspended`.
- Server-side functions can verify admin claims via custom claims before acting.
- Rate limiting and cooldown logic must run on the server to be tamper-proof.

**Status:** Functions written and compiling in `functions/src/index.ts`; Dart services wired in `lib/core/services/admin_functions_service.dart` and `lib/core/services/project_functions_service.dart`. Not yet deployed because the project is on the Spark plan.
