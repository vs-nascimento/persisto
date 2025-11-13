## persisto

`persisto` is an offline-first interception and caching toolkit for Dart and Flutter. Plug it into any repository (REST, Firebase, Supabase, SQLite, or custom APIs) and it will:

- Intercept read/write operations.
- Apply cache policies per data source.
- Serve cached responses automatically when the network fails.
- Queue mutations offline and replay them when connectivity returns.

---

## Installation

Add `persisto` to your project:

```yaml
dependencies:
  persisto: ^0.3.0
```

This package bundles ready-to-use adapters for `package:http`, Dio, Cloud Firestore, and Supabase, plus cache backends powered by memory, Hive, SharedPreferences, and Sqflite. No extra dependencies are required beyond the ones already declared by the package, but you must initialise platform plugins where required (e.g. `Hive.initFlutter()`, Sqflite database path).

---

## Quick start

```dart
import 'package:persisto/persisto.dart';

Future<void> bootstrap() async {
  final cache = SharedPreferencesCache();

  final interceptor = OfflineInterceptor(
    cache: cache,
    policies: {
      'posts': CachePolicy(
        ttl: const Duration(minutes: 10),
        strategy: CacheStrategy.cacheFirst,
      ),
    },
  );

  final httpAdapter = HttpAdapter(baseUrl: 'https://example.com');

  final posts = await interceptor.fetch(
    source: 'posts',
    key: '/posts',
    request: () => httpAdapter.get('/posts'),
  );

  print(posts);
}
```

Override behaviour per call when necessary:

```dart
final freshPosts = await interceptor.fetch(
  source: 'posts',
  key: '/posts?filter=hot',
  request: () => httpAdapter.get('/posts', params: {'filter': 'hot'}),
  strategyOverride: CacheStrategy.networkFirst,
  ttlOverride: const Duration(minutes: 2),
  compareWithCache: true,
  refreshCacheOnEquality: false,
  equalityComparer: (cached, fresh) =>
      const DeepCollectionEquality.unordered().equals(cached, fresh),
);
```

---

## Cache backends

| Cache class | When to use | Notes |
| --- | --- | --- |
| `MemoryCache` | Unit tests, short-lived sessions | Pure Dart, no setup |
| `SharedPreferencesCache` | Lightweight key-value persistence | Works out of the box on all Flutter platforms |
| `HiveCache` | Structured offline storage | Call `Hive.initFlutter()` and `HiveCache().init()` before usage |
| `SqfliteCache` | Durable cache with SQL querying | Provide a writable database path when constructing the cache |

```dart
final cache = SqfliteCache(databasePath: '/data/user/0/app/cache/persisto.db');
await cache.write('users', {'data': []});
```

---

## Built-in adapters

| Adapter | Package | Highlights |
| --- | --- | --- |
| `HttpAdapter` | `package:http` | Zero-config REST client |
| `DioAdapter` | `dio` | Interceptors, cancellation, retries |
| `FirebaseAdapter` | `cloud_firestore` | Query customisation and realtime listeners |
| `SupabaseAdapter` | `supabase_flutter` | Select/filter helpers and realtime streams |

Implement `DataAdapter` to integrate any other backend.

---

## Cache comparison helpers

Skip unnecessary cache rewrites by enabling payload comparison:

```dart
await interceptor.fetch(
  source: 'profile',
  key: '/profile/me',
  request: () => httpAdapter.get('/profile/me'),
  compareWithCache: true,
  equalityComparer: (cached, fresh) =>
      cached['updatedAt'] == fresh['updatedAt'],
);
```

When the comparer returns `true`, the cached copy is reused (optionally refreshing TTL) and the network response is discarded.

---

## Sync queue for offline mutations

```dart
final syncManager = SyncManager();

syncManager.enqueue(
  SyncOperation('/posts', 'POST', {'title': 'Offline post'}),
);

await syncManager.processQueue((op) async {
  switch (op.method) {
    case 'POST':
      await httpAdapter.post(op.path, op.body);
      break;
    case 'PUT':
      await httpAdapter.put(op.path, op.body);
      break;
    case 'DELETE':
      await httpAdapter.delete(op.path);
      break;
  }
});
```

Call `processQueue` after regaining connectivity to replay pending operations.

---

## Error handling

`persisto` provides comprehensive error handling with specific exception types that allow you to handle different error scenarios appropriately:

```dart
try {
  final data = await interceptor.fetch(
    source: 'posts',
    key: '/posts',
    request: () => httpAdapter.get('/posts'),
  );
} on HttpException catch (e) {
  // Handle HTTP errors (4xx, 5xx)
  print('HTTP Error ${e.statusCode}: ${e.message}');
  if (e.responseBody != null) {
    print('Response: ${e.responseBody}');
  }
  if (e.isClientError) {
    // Client error (4xx) - bad request, not found, etc.
  } else if (e.isServerError) {
    // Server error (5xx) - internal server error, etc.
  }
} on NetworkException catch (e) {
  // Handle network errors (timeout, connection failures, etc.)
  print('Network Error: ${e.message}');
} on CacheException catch (e) {
  // Handle cache errors
  print('Cache Error: ${e.message}');
} on PolicyException catch (e) {
  // Handle cache policy configuration errors
  print('Policy Error: ${e.message}');
} on AdapterException catch (e) {
  // Handle adapter-specific errors
  print('Adapter Error: ${e.message}');
} on PersistoException catch (e) {
  // Handle other Persisto errors
  print('Persisto Error: ${e.message}');
} catch (e) {
  // Handle unexpected errors
  print('Unexpected Error: $e');
}
```

### Exception types

- **`PersistoException`**: Base class for all Persisto-related errors
- **`NetworkException`**: Thrown when network requests fail (timeout, connection errors, etc.)
- **`HttpException`**: Thrown when HTTP requests return non-success status codes (includes `statusCode`, `responseBody`, `isClientError`, `isServerError`)
- **`CacheException`**: Thrown when cache operations fail or cache is unavailable
- **`AdapterException`**: Thrown when adapter operations fail (Firebase, Supabase, etc.)
- **`PolicyException`**: Thrown when cache policy configuration is invalid or missing

All exceptions include a `message` and optional `cause` (the underlying exception) for detailed error information.

---

## Example app

The Flutter example in `example/lib/main.dart` fetches the public PokeAPI feed and lets you:

- Switch between Hive, SharedPreferences, and in-memory caches.
- Override TTL and cache strategy per request.
- Toggle equality comparison to avoid unnecessary cache writes.
- Adjust pagination (`limit`/`offset`) and observe how cache keys change.

Run it with:

```bash
cd example
flutter run
```

---

## Maintenance helpers

```dart
await cache.delete('/posts'); // Drop a single entry
await cache.clear(); // Flush entire cache
```

---

## Testing checklist

1. Inject fake adapters and caches via `DataAdapter` / `CacheStorage` implementations.
2. Simulate TTL expiry by tweaking stored timestamps.
3. Verify equality comparers skip cache writes.
4. Cover sync queue success and retry scenarios.

---

## Contributing

1. Fork and clone the repository.
2. Create a feature branch.
3. Implement changes + tests.
4. Run `flutter analyze`, `flutter test`, and `dart pub publish --dry-run`.
5. Submit a pull request describing your work.
