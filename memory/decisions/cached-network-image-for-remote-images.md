# Decision: Use cached_network_image for remote images

**Decision:** Replace all `Image.network` usages with `cached_network_image` to cache remote images locally.

**Rationale:**
- Reduces network traffic and improves scroll performance in lists.
- Provides built-in placeholder and error widgets.
- Already declared as a dependency; was unused before this decision.

**Status:** Implemented via a reusable `AppNetworkImage` widget and `CachedNetworkImageProvider` for avatars.
