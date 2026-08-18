# Decision: Use Node.js admin SDK for Firestore seed script

**Decision:** Implement the demo-data seed script as a standalone TypeScript Node.js script using `firebase-admin`.

**Rationale:**
- The Admin SDK bypasses Firestore security rules, so the script can write user docs and projects freely.
- Can reuse the same mock data defined in `lib/core/services/mock_data_service.dart`.
- Easier to run as a one-off CLI tool than a Dart script that needs Flutter and auth context.

**Status:** Implemented in `scripts/seed_firestore.ts`.
