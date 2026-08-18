# Decision: Use composite IDs for saved_projects

**Decision:** Store saved-project relationships as documents with composite IDs: `saved_projects/{uid}_{projectId}`.

**Rationale:**
- A single document ID encodes both the user and the project, making ownership checks simple and efficient.
- Firestore rules can validate ownership with a `matches(uid + '_.*')` check.
- Avoids an extra index or query to enforce one-save-per-user-per-project.

**Status:** Implemented in `SavedProjectRepository` and `firestore.rules`.
