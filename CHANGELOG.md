## 0.1.0 - 2025-11-12

- Renamed the public package to `persisto` and updated exports.
- Rewrote the README with new installation instructions and usage guides.
- Added MIT license text and improved project metadata.
- Replaced placeholder calculator test with smoke test for `OfflineInterceptor`.

## 0.0.1

- Initial release of `persisto`.
- Provides cache-aware `OfflineInterceptor.fetch` with strategy/TTL overrides.
- Ships HTTP (http + Dio), Firestore, and Supabase adapters.
- Includes Hive and in-memory cache implementations.
- Adds sync queue utilities for offline mutations.
- Bundles PokeAPI example app showcasing cache comparison controls.
