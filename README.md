## persisto

`persisto` is a framework-agnostic interception and caching layer tailored for offline-first experiences. Plug it into any repository - REST, Firebase, Supabase, SQLite, or custom APIs - and it will:

- Intercept read/write operations.
- Apply cache policies per data source.
- Serve cached responses automatically when the network fails.
- Sync queued mutations once connectivity returns.

---

## Highlights

- **Adapters included:** HTTP (`package:http`), Dio, Cloud Firestore, Supabase.
- **Per-request overrides:** change strategy or TTL dynamically in `fetch`.
- **Equality-aware cache updates:** avoid rewriting cache when payloads match.
- **Sync queue:** persist POST/PUT/DELETE intents and replay online.
- **Framework agnostic:** works with Flutter or plain Dart.

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  persisto: ^0.1.0
  http: ^1.2.2
  dio: ^5.4.3
  hive: ^2.2.3
  connectivity_plus: ^6.0.3
```

Optional:

- `firebase_core`, `cloud_firestore`
- `supabase_flutter`

Initialize Hive before using the cache:

```dart
await Hive.initFlutter();
final cache = HiveCache();
await cache.init();
```

---

## Quick start

```dart
final httpAdapter = HttpAdapter(baseUrl: 'https://example.com/api');
final dioAdapter = DioAdapter(baseUrl: 'https://example.com/api');
final firebaseAdapter = FirebaseAdapter(collectionPath: 'posts');
final supabaseAdapter = SupabaseAdapter(
  client: Supabase.instance.client,
  table: 'posts',
);

final interceptor = OfflineInterceptor(
  cache: cache,
  policies: {
    'posts': CachePolicy(
      ttl: const Duration(hours: 2),
      strategy: CacheStrategy.cacheFirst,
    ),
    'profile': CachePolicy(
      ttl: const Duration(minutes: 10),
      strategy: CacheStrategy.networkFirst,
    ),
  },
);

final posts = await interceptor.fetch(
  source: 'posts',
  key: '/posts',
  request: () => httpAdapter.get('/posts'),
);
```

Override per call:

```dart
final hotPosts = await interceptor.fetch(
  source: 'posts',
  key: '/posts?filter=hot',
  request: () => dioAdapter.get('/posts', params: {'filter': 'hot'}),
  strategyOverride: CacheStrategy.networkFirst,
  ttlOverride: const Duration(minutes: 5),
  compareWithCache: true,
  refreshCacheOnEquality: false,
  equalityComparer: (cached, fresh) =>
      const DeepCollectionEquality.unordered().equals(cached, fresh),
);
```

---

## Cache comparison helpers

Skip cache rewrites when responses match:

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

---

## Sync queue

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

Invoke `processQueue` whenever connectivity is restored.

---

## Example app

`example/lib/main.dart` demonstrates the library with the public [PokeAPI](https://pokeapi.co/):

- Switch cache strategies per request.
- Adjust TTL overrides.
- Toggle equality comparison & TTL refresh.
- Tune pagination (`limit`/`offset`) and observe cache-key changes.

Run it with:

```bash
cd example
flutter run
```

---

## Maintenance utilities

```dart
await cache.delete('/posts'); // Drop a single entry.
await cache.clear(); // Flush entire cache.
```

---

## Testing checklist

1. Inject mock adapters/caches via `DataAdapter` and `CacheStorage`.
2. Validate TTL expiry by stubbing cache timestamps.
3. Assert equality comparers skip cache writes.
4. Cover sync-queue replay success & failure paths.

---

## Contributing

1. Fork & clone the repository.
2. Create a feature branch.
3. Implement changes + tests.
4. Run `flutter analyze` and `flutter test`.
5. Open a pull request describing the change.
