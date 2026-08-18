# Known Issues

## Functional limitations

1. **Admin promote/demote/suspend work without Cloud Functions (Spark plan fallback)**
   - `AdminFunctionsService` now tries the callable function first, then falls back to direct Firestore writes through `UserRepository`.
   - Firestore rules identify admins by the `role` field on their own `users/{uid}` doc and allow admin-only updates to `role`/`isSuspended`.
   - **Limitation:** delete-user only removes the Firestore user doc and the `usernames/{username}` reservation. The Firebase Auth account still exists because client code cannot delete another user's Auth account without the Admin SDK or a deployed Cloud Function.

2. **Project submission rate-limiting is inactive (requires Blaze plan)**
   - `checkProjectSubmissionRate` callable function is not deployed.
   - The client falls back to `allowed: true`.
   - Impact: Users can publish unlimited projects.
   - Fix: Upgrade to Blaze and deploy Cloud Functions.

3. **View counting is inactive (requires Blaze plan)**
   - `incrementProjectView` callable function is not deployed.
   - Client swallows the error silently.
   - Impact: `viewCount` stays at static values.
   - Fix: Upgrade to Blaze and deploy Cloud Functions.

4. **Firestore queries need composite indexes**
   - Some paginated queries will throw an index error on first run.
   - Required indexes:
     - `projects`: `status` ascending, `createdAt` descending
     - `projects`: `category` ascending, `status` ascending, `createdAt` descending
     - `projects`: `ownerId` ascending, `createdAt` descending
   - Fix: Create indexes in Firebase Console (link appears in error message).

5. **Search is client-side only**
   - Firestore has no native full-text search.
   - The app fetches approved projects and filters locally (limited to 100).
   - Impact: Search results are limited and not scalable.
   - Workaround: Algolia or a dedicated search Cloud Function for production.

6. **~~Cloudinary upload preset must allow raw files for documents~~** ✅ Verified
   - The unsigned upload preset accepts both images and raw files.
   - `test_cloudinary_upload.py` confirmed successful image and text/raw uploads.
   - If you later restrict the preset, ensure `raw` uploads remain enabled for documents.

## Platform notes

7. **iOS not configured**
   - `firebase_options.dart` throws `UnsupportedError` on iOS/macOS/Windows/Linux.
   - This is intentional for this project.
   - On those platforms the app falls back to mock data if Firebase init is skipped.

8. **App Check may fail on Android**
   - Play Integrity is not enrolled in the Firebase console.
   - The app catches the error and continues; Firebase services still work without strict attestation.

## Code / maintenance notes

9. **Stale `notification` collection (singular) with wrong schema**
   - Firestore has an old `notification` collection containing a doc with fields that don't match `NotificationModel`.
   - The app reads from `notifications` (plural).
   - Fix: Delete the `notification` collection from the Firebase Console if it's no longer needed.

10. **~~Cloud Function `logAuditEntry` does not verify admin claim~~** ✅ Fixed
   - `logAuditEntry` now calls `assertAdmin` before writing an audit entry.

11. **~~Old scratch file `fbs-data.js` exists at project root~~** ✅ Fixed
    - File deleted; hosting config is already in `firebase.json`.
