# Todo

## Priority 1 — no Firebase upgrade needed

1. [x] **Deploy Firestore rules**
   - Run: `firebase deploy --only firestore:rules`
   - ✅ Deployed successfully.

2. [x] **Switch media uploads to Cloudinary**
   - ✅ Replaced Firebase Storage with `cloudinary_public`.
   - ✅ Credentials configured in `lib/core/services/cloudinary_config.dart`.
   - ✅ Removed `firebase_storage` dependency and `storage.rules`.

3. [x] **Deploy Firebase Hosting**
   - ✅ Live at https://saas-management-du664-58970.web.app

4. [x] **Test web app registration with fake/temp users**
   - ✅ Registered 3 temp-mail users via Playwright.

5. [x] **Implement unique username enforcement**
   - Added `usernames/{username}` collection and transactional signup reservation.
   - Added debounced availability indicator on the register screen.
   - Updated Firestore rules; deployed.

6. [x] **Test media upload end-to-end via Cloudinary**
   - Verified the unsigned preset accepts both images and raw files with `test_cloudinary_upload.py`.
   - Fixed `StorageService` so image uploads fall back to raw bytes on web (where `flutter_image_compress` cannot compress file paths).
   - Rebuilt and redeployed the web app to Firebase Hosting.

6. [x] **Make admin promote/demote/suspend work on Spark plan**
   - `AdminFunctionsService` now tries the callable function, then falls back to direct Firestore writes through `UserRepository`.
   - Firestore rules identify admins by the `role` field on their own `users/{uid}` doc and allow admin-only updates to `role` and `isSuspended`.
   - Updated and deployed `firestore.rules`.
   - **Note:** Delete-user still cannot remove the Firebase Auth account without Cloud Functions/Admin SDK; it only deletes the Firestore user doc and username reservation.

## Priority 2 — requires Firebase Blaze upgrade

7. [ ] **Upgrade Firebase project to Blaze plan**

8. [ ] **Deploy Cloud Functions**
   - Run: `cd functions && npm run build && firebase deploy --only functions`

9. [ ] **Test admin functions via deployed Cloud Functions**
   - Full delete-user (Auth account + Firestore doc) through Admin SDK.

10. [ ] **Verify rate limiting and view counting**
   - Publish more than 5 projects in 24h should be blocked.
   - Repeated project views should respect 1-hour cooldown.

## Priority 3 — optional polish / hardening

10. [ ] **Enable Play Integrity / App Check** in Firebase Console.
11. [x] **Add more demo projects** to seed script for a richer explore feed.
12. [x] **Add loading/error empty states** where missing.
13. [x] **Add integration/widget tests** for core flows.
    - Onboarding navigation (`integration_test/app_test.dart`).
    - Explore feed, category filters, search, and project detail (`test/features/`).
14. [ ] **Evaluate Algolia or similar** for full-text search instead of client-side filtering.
15. [x] **Tighten `logAuditEntry` Cloud Function** to verify admin claim.

## Intentionally not doing

- [ ] iOS Firebase configuration (not required for this project).
- [x] Firebase Storage for media (replaced by Cloudinary).
