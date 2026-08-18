# AcquireBase — Addendum: Unique Username Field + Real Firestore Deployment

## Part A — Add `username` with real uniqueness enforcement

Firestore does not have a native unique-field constraint like SQL. Two users could otherwise grab the same username in a race condition if this isn't handled deliberately. Use the standard Firestore pattern:

### New collection: `usernames/{username}`
- Document ID = the username itself (lowercase, normalized).
- Document body: `{ uid: String }` — just a pointer back to the owning user.
- This collection's only purpose is to make "is this username taken" a fast, atomic existence check.

### Registration flow change
When a user signs up and picks a username:
1. Normalize it (lowercase, trim).
2. Validate format: 3–20 characters, lowercase letters/numbers/underscores only, no spaces — reasonable defaults, adjust if you want different rules, but confirm with me if you change them.
3. Inside a **Firestore transaction** (not two separate writes — this must be atomic to actually prevent the race condition):
   - Read `usernames/{normalizedUsername}` — if it already exists, abort and show "username already taken."
   - If it doesn't exist, write `usernames/{normalizedUsername} = { uid }` AND create the `users/{uid}` doc (with the username included) in the same transaction.
4. Show a real-time "checking availability..." indicator on the Register form as the user types (debounced — don't check on every keystroke, wait ~500ms after typing stops) by reading `usernames/{typedUsername}` directly (a read is allowed publicly per the rules below; only the transactional write is restricted).

### Confirm with me: are usernames changeable later?
Default assumption unless you say otherwise: **usernames are immutable after signup** (common pattern — avoids identity churn/impersonation issues, and simplifies the uniqueness logic since you never need to release an old reservation). If you want it changeable later, flag that now since it changes the design (would need to delete the old `usernames/{old}` doc and create a new one, transactionally, whenever changed).

### Firestore rules for the new collection
```
match /usernames/{username} {
  allow read: if true; // needed for the availability-check UI
  allow create: if request.auth != null
    && request.resource.data.uid == request.auth.uid
    && username == username.lower(); // enforce normalized form
  allow update, delete: if false; // immutable once claimed (per default assumption above)
}
```
Adjust if the "changeable later" answer above is different.

---

## Part B — Confirmed final `users/{uid}` schema (camelCase normalized)

```
uid: String                          — Primary Key, = Firebase Auth UID
email: String                        — mirrors Firebase Auth email
username: String                     — unique, see usernames/{username} above
firstName: String
lastName: String
displayName: String                  — computed "$firstName $lastName" at signup
age: Number
skills: Array<String>
profession: String ("Student" | "Employee" | "Self-Employed" | "Founder" | "Other")
bio: String
socialLinks: { twitter: String, linkedin: String, website: String }
role: String ("user" | "admin")      — NEVER client-writable
isSuspended: Boolean                 — NEVER client-writable
createdAt: Timestamp
profileViews: Number
publishedProjectIds: Array<String>   — Foreign Key → projects.projectId
savedProjectIds: Array<String>       — Foreign Key → projects.projectId
```

Verify this matches (or update) the current `UserModel` and `UserRepository` — reconcile any naming mismatch (e.g. if the current code has lowercase `firstname` anywhere, rename to `firstName` consistently, including in `firestore.rules` field validation).

Confirm `role` and `isSuspended` are still excluded from every client-side write path, including the new registration transaction above — the transaction should only ever write these two fields with their default values (`role: "user"`, `isSuspended: false`) at creation time, never let a later client update touch them.

---

## Part C — Actually deploy this to real Firebase (the part that's been pending)

Per the last status report, Firestore rules were written but not yet deployed. Do this now:

1. **Confirm Firestore Database is enabled** in the Firebase Console for this project (Build → Firestore Database → if not already created, create it in Production mode, same region as the rest of the project's services). Tell me exactly where to click if I need to do this part myself.
2. Update `firestore.rules` with the `usernames` collection rules above (in addition to whatever's already there for `users`, `projects`, etc.).
3. Deploy: `firebase deploy --only firestore:rules`
4. Confirm the deploy succeeded — show me the actual terminal output, don't just assume it worked.
5. Test the full registration flow end-to-end against the real deployed Firestore (not mock data) — create a real test account, confirm the `users/{uid}` doc and `usernames/{username}` doc both appear correctly in the Firebase Console's Firestore data viewer, and confirm a second signup attempt with the same username is correctly rejected.

---

## Process
Build Part A first (transaction logic + rules + registration UI update), show me the registration screen's new username field behavior, then move to Part C (actual deployment) once I confirm Part A looks right. Update the memory vault (`memory/`) with this as a new decision entry once done.