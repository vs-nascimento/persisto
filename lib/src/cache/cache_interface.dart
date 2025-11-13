/// Contract for storage layers plugged into [OfflineInterceptor].
abstract class CacheStorage {
  /// Persists [value] under the provided [key].
  Future<void> write(String key, dynamic value);

  /// Returns the value stored for [key] or `null` when absent.
  Future<dynamic> read(String key);

  /// Removes the entry stored under [key].
  Future<void> delete(String key);

  /// Clears all cached entries.
  Future<void> clear();
}
