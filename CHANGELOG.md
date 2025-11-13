## 0.3.0 - 2025-01-XX

- **Breaking change**: Added comprehensive error handling with custom exception classes.
- Introduced `PersistoException` base class and specialized exceptions:
  - `NetworkException` for network-related errors (timeout, connection failures)
  - `HttpException` for HTTP errors (4xx, 5xx) with status code and response body
  - `CacheException` for cache operation failures
  - `AdapterException` for adapter-specific errors
  - `PolicyException` for cache policy configuration errors
- Updated all adapters (`HttpAdapter`, `DioAdapter`, `FirebaseAdapter`, `SupabaseAdapter`) to throw appropriate exceptions instead of generic errors.
- Enhanced `OfflineInterceptor` to propagate errors more informatively while attempting to return cached data when available.
- Improved error messages with context and underlying exception causes.

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
