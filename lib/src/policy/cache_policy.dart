/// Strategy describing how network/cache should be prioritised.
enum CacheStrategy {
  /// Attempt the network first, fallback to cache when offline or on failure.
  networkFirst,

  /// Reuse cache when fresh, otherwise hit the network.
  cacheFirst,

  /// Never touch the network, always return cached data.
  cacheOnly,
}

/// Configuration used by [OfflineInterceptor] to manage entries.
class CachePolicy {
  /// Creates a policy with [ttl] and [strategy].
  const CachePolicy({
    required this.ttl,
    this.strategy = CacheStrategy.networkFirst,
  });

  /// Maximum age for cached data before it is considered expired.
  final Duration ttl;

  /// Defines how cache interacts with the network.
  final CacheStrategy strategy;
}
