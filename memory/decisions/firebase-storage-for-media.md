# Decision: Use Cloudinary for media uploads

**Decision:** Store user avatars, project logos, project screenshots, and project documents in Cloudinary instead of Firebase Storage.

**Rationale:**
- Avoids needing to enable and configure Firebase Storage in the console.
- Cloudinary handles image optimization, transformations, and CDN delivery.
- Unsigned upload presets let the Flutter client upload directly without exposing API secrets.
- Keeps the Firebase project on the free Spark plan without Storage usage.

**Status:** Implemented in `lib/core/services/storage_service.dart` and `lib/core/services/cloudinary_config.dart`.

**Note:** Firebase Storage was originally chosen (see earlier version of this file) but was replaced because the project does not have Storage enabled in the Firebase console.
