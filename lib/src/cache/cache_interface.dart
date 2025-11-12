abstract class CacheStorage {
  Future<void> write(String key, dynamic value);

  Future<dynamic> read(String key);

  Future<void> delete(String key);

  Future<void> clear();
}
