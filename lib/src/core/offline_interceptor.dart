import 'package:collection/collection.dart';

import '../cache/cache_interface.dart';
import '../policy/cache_policy.dart';
import '../utils/network_checker.dart';

/// Coordinates network calls, caching, and offline recovery.
class OfflineInterceptor {
  /// Creates a new interceptor with the provided [cache] and [policies].
  OfflineInterceptor({required this.cache, required this.policies});

  /// Storage used to persist responses.
  final CacheStorage cache;

  /// Policy map keyed by `source` identifiers.
  final Map<String, CachePolicy> policies;

  /// Fetches data while respecting caching rules and network availability.
  ///
  /// * [source] selects the [CachePolicy] to apply.
  /// * [key] is the cache identifier for the request payload.
  /// * [request] is invoked to fetch fresh data when needed.
  /// * [strategyOverride] and [ttlOverride] allow per-call adjustments.
  /// * When [compareWithCache] is `true` the optional [equalityComparer]
  ///   decides whether the cache should be refreshed.
  Future<dynamic> fetch({
    required String source,
    required String key,
    required Future<dynamic> Function() request,
    CacheStrategy? strategyOverride,
    Duration? ttlOverride,
    bool compareWithCache = false,
    bool refreshCacheOnEquality = true,
    bool Function(dynamic cached, dynamic fresh)? equalityComparer,
  }) async {
    final policy = policies[source];

    final resolvedTtl = ttlOverride ?? policy?.ttl;
    if (resolvedTtl == null) {
      throw Exception(
        'No cache policy defined for $source. '
        'Provide a policy in the interceptor or pass ttlOverride.',
      );
    }

    final resolvedStrategy =
        strategyOverride ?? policy?.strategy ?? CacheStrategy.networkFirst;

    final cacheData = await cache.read(key);
    final cacheTimestamp = cacheData?['timestamp'];
    final cacheValue = cacheData?['data'];

    final cacheExpired =
        cacheTimestamp != null &&
        DateTime.now().millisecondsSinceEpoch - cacheTimestamp >
            resolvedTtl.inMilliseconds;

    if (resolvedStrategy == CacheStrategy.cacheOnly) {
      if (cacheValue != null && !cacheExpired) return cacheValue;
      if (cacheValue != null) return cacheValue;
      throw Exception(
        'Cache only strategy enabled but no cache available for $key.',
      );
    }

    if (resolvedStrategy == CacheStrategy.cacheFirst &&
        cacheValue != null &&
        !cacheExpired) {
      return cacheValue;
    }

    final online = await NetworkChecker.isOnline;
    if (online) {
      try {
        final data = await request();
        if (compareWithCache && cacheValue != null) {
          final equals =
              equalityComparer?.call(cacheValue, data) ??
              const DeepCollectionEquality().equals(cacheValue, data);
          if (equals) {
            if (refreshCacheOnEquality) {
              await cache.write(key, cacheValue);
            }
            return cacheValue;
          }
        }

        await cache.write(key, data);
        return data;
      } catch (_) {
        if (cacheValue != null) return cacheValue;
        rethrow;
      }
    } else {
      if (cacheValue != null) return cacheValue;
      throw Exception('No network and no cache available.');
    }
  }
}
