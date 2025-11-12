enum CacheStrategy { networkFirst, cacheFirst, cacheOnly }

class CachePolicy {
  final Duration ttl;
  final CacheStrategy strategy;

  const CachePolicy({
    required this.ttl,
    this.strategy = CacheStrategy.networkFirst,
  });
}

