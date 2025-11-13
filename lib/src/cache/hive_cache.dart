import 'dart:convert';

import 'package:hive/hive.dart';

import 'cache_interface.dart';

/// Hive-backed cache that stores JSON-encoded payloads.
class HiveCache implements CacheStorage {
  /// Creates a cache stored in Hive [boxName].
  HiveCache({this.boxName = 'persisto_cache'});

  /// Box used to persist entries.
  final String boxName;

  late Box _box;

  /// Opens the Hive box. Call before the first read/write.
  Future<void> init() async {
    _box = await Hive.openBox(boxName);
  }

  @override
  Future<void> write(String key, dynamic value) async {
    await _box.put(
      key,
      jsonEncode({
        'data': value,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }),
    );
  }

  @override
  Future<dynamic> read(String key) async {
    final json = _box.get(key);
    if (json == null) return null;
    return jsonDecode(json);
  }

  @override
  Future<void> delete(String key) async => _box.delete(key);

  @override
  Future<void> clear() async => _box.clear();
}
