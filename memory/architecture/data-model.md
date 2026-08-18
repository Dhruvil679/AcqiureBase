# Firestore Data Model

## Collections

### `users/{uid}`

One document per registered user.

```yaml
uid: string
username: string
email: string
firstName: string
lastName: string
displayName: string
age: int?
skills: List<string>
profession: string  # student | employee | selfEmployed | founder | other
photoUrl: string
bio: string
socialLinks:
  twitter: string
  linkedin: string
  website: string
role: string          # "user" | "admin"
isSuspended: boolean
createdAt: timestamp
profileViews: int
publishedProjectIds: List<string>
savedProjectIds: List<string>
updatedAt: timestamp?
```

**Notes:**
- `role` and `isSuspended` are set only by Cloud Functions / admin SDK.
- Firestore rules block clients from writing these fields.

---

### `projects/{projectId}`

One document per project submission.

```yaml
projectId: string
ownerId: string
name: string
logoUrl: string
tagline: string
description: string
category: string      # saas | aiTools | webApps | ... | other
websiteUrl: string
businessAge: string
monthlyVisitors: string
screenshotUrls: List<string>
documentUrls: List<string>
founderName: string
founderBio: string
status: string        # pending | approved | rejected | removed
isFeatured: boolean
createdAt: timestamp
updatedAt: timestamp?
saveCount: int
viewCount: int
```

**Notes:**
- New submissions default to `status: pending`.
- Only admins can write `status`, `isFeatured`, `saveCount`, `viewCount`.
- Owners can update content fields on their own pending/approved projects.

---

### `saved_projects/{uid}_{projectId}`

Composite ID doc representing a saved project.

```yaml
uid: string
projectId: string
```

**Notes:**
- Document ID must be `{uid}_{projectId}`.
- Users can only read/write docs where the ID starts with their own UID.

---

### `auditLogs/{entryId}`

Admin action log.

```yaml
adminUid: string
adminName: string
action: string
targetType: string    # "user" | "project"
targetId: string
targetName: string
reason: string?
timestamp: timestamp
```

**Notes:**
- Admin-only read/write.

---

### `activityLogs/{entryId}`

General user activity.

```yaml
uid: string
action: string        # login | project_published | project_edited | project_saved | project_unsaved | profile_updated
timestamp: timestamp
metadata: Map<string, dynamic>
```

**Notes:**
- Users read only their own activity; admins read any.

---

### `projects/{projectId}/history/{historyEntryId}`

Project edit history.

```yaml
editedBy: string
timestamp: timestamp
changedFields: List<string>
previousValues: Map<string, dynamic>
```

**Notes:**
- Written by `ProjectRepository.updateProject()`.
- Readable by project owner and admins.

---

### `notifications/{notificationId}`

User notifications for project status changes.

```yaml
userId: string
projectId: string
title: string
body: string
type: string          # projectApproved | projectRejected | projectRemoved
isRead: boolean
timestamp: timestamp
```

**Notes:**
- Created by admins via `NotificationRepository`.
- Users can only update `isRead` to `true`.

---

### `rateLimits/{uid}`

Managed by Cloud Functions only.

```yaml
projectSubmissions: List<timestamp>
```

**Notes:**
- Clients cannot write this collection.
- Subcollection `views/{projectId}` tracks per-project view cooldowns.

## Relationships

- `projects.ownerId` → `users/{uid}`
- `saved_projects.projectId` → `projects/{projectId}`
- `activityLogs.metadata.projectId` → `projects/{projectId}`
- `notifications.projectId` → `projects/{projectId}`
