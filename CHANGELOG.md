## 0.2.0 - 2025-11-12

- Renamed the package entry point to `persisto` and updated exports.
- Added `SharedPreferencesCache` and `SqfliteCache` alongside the existing Hive and memory caches.
- Documented public APIs (policies, caches, adapters, interceptor, sync manager) and refreshed the README with detailed examples.
- Replaced the placeholder calculator test with a smoke test for `OfflineInterceptor` + `MemoryCache`.
- Upgraded runtime dependencies (dio, cloud_firestore, connectivity_plus, supabase_flutter, http, collection) to their latest stable releases.

## 0.1.0 - 2025-11-12

- Initial release of `persisto`.
- Provides cache-aware `OfflineInterceptor.fetch` with strategy/TTL overrides.
- Ships HTTP (http + Dio), Firestore, and Supabase adapters.
- Includes Hive and in-memory cache implementations.
- Adds sync queue utilities for offline mutations.
- Bundles PokeAPI example app showcasing cache comparison controls.
