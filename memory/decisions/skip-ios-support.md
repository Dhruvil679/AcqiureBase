# Decision: Skip iOS support

**Decision:** Do not configure Firebase for iOS/macOS/Windows/Linux. Target Android and Web only.

**Rationale:**
- The project is a college/demo app; Android and Web are sufficient for demonstration.
- Skipping iOS avoids needing Apple Developer account, provisioning, and Firebase iOS app registration.
- Unconfigured platforms gracefully fall back to mock data.

**Status:** `firebase_options.dart` and `firebase.json` include Android + Web only. iOS/macOS/Windows/Linux throw `UnsupportedError` and fall back to mock mode.
