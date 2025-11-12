import 'cache_interface.dart';

class MemoryCache implements CacheStorage {
  final Map<String, _CacheEntry> _store = {};

  @override
  Future<void> write(String key, dynamic value) async {
    _store[key] = _CacheEntry(
      value: value,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<dynamic> read(String key) async {
    final entry = _store[key];
    if (entry == null) return null;
    return {'data': entry.value, 'timestamp': entry.timestamp};
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }
}

class _CacheEntry {
  final dynamic value;
  final int timestamp;

  _CacheEntry({required this.value, required this.timestamp});
}
