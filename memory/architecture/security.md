# Security Model

## Authentication

- Firebase Authentication via email/password.
- Email verification required before publishing a project.
- Cloud Functions can set custom claims (`role: admin`) on Auth tokens.

## Custom claims

- `role`: `"admin"` or `"user"`
- Set by the `setAdminClaim` callable function.
- Firestore rules read `request.auth.token.role` to determine admin status.
- Custom claims take effect on the user's next ID token refresh.

## Firestore rules summary

### `users/{uid}`
- Read: own doc or admin.
- Create: own doc only; `role` must be `"user"`, `isSuspended` must be `false`.
- Update: own doc only; cannot write `role`, `isSuspended`, `uid`.
- Delete: admin only (intended via Cloud Function).

### `projects/{projectId}`
- Read: public if `status == approved`; owner or admin can read any status.
- Create: authenticated; forced `ownerId == request.auth.uid` and `status == pending`.
- Update: admin can update any field; owner can update content fields but never `status`, `isFeatured`, `saveCount`, `viewCount`, `ownerId`, `projectId`.
- Delete: owner or admin.

### `saved_projects/{uid}_{projectId}`
- Read/write: only the UID encoded in the composite doc ID.

### `auditLogs/{entryId}`
- Read/create: admin only.
- Update/delete: never.

### `activityLogs/{entryId}`
- Read: own activity or admin.
- Create: own activity only with allowed action values.
- Update/delete: never.

### `projects/{projectId}/history/{historyEntryId}`
- Read/create: project owner or admin.
- Update/delete: never.

### `notifications/{notificationId}`
- Read: owning user.
- Create: admin.
- Update: owning user can only mark `isRead: true`.
- Delete: never.

### `rateLimits/{uid}`
- Read: own doc.
- Write: never (Cloud Functions only).

## Storage rules summary

### `users/{uid}/avatar/{fileName}`
- Read: public.
- Write: own UID, image type, ≤ 5 MB.
- Delete: own UID or admin.

### `projects/{projectId}/logo/{fileName}`
### `projects/{projectId}/screenshots/{fileName}`
- Read: public.
- Write: authenticated project owner or admin, image type, ≤ 5 MB.
- Delete: authenticated project owner or admin.

### `projects/{projectId}/documents/{fileName}`
- Read: public.
- Write: authenticated project owner or admin, document type (PDF/DOC/DOCX/TXT), ≤ 10 MB.
- Delete: authenticated project owner or admin.

## Rate limiting

Server-side only, implemented in Cloud Functions:

- **Project submission rate limit:** 5 projects per 24-hour window per user.
- **View count cooldown:** one counted view per user per project per hour.

Without deployed functions, these protections are inactive; the client falls back to no rate limiting and no view counting.

## Admin operations

The following require Cloud Functions because Firestore rules block direct client writes:

- Promote/demote user (`setAdminClaim`)
- Suspend/activate user (`setUserSuspension`)
- Delete user (`deleteUserAccount`)

These functions verify the caller is an admin via custom claim before acting.
