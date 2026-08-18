# Decision: Use Riverpod for state management

**Decision:** Use `flutter_riverpod` as the primary state management solution.

**Rationale:**
- Compile-safe dependency injection and provider scoping.
- Built-in support for `StreamProvider` and `FutureProvider`, which map cleanly to Firestore streams and async repository calls.
- No need for `BuildContext` to read dependencies, making services easier to test and reuse.

**Status:** Implemented across the app.
