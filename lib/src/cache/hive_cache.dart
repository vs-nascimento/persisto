import 'dart:convert';

import 'package:hive/hive.dart';

import 'cache_interface.dart';

class HiveCache implements CacheStorage {
  final String boxName;
  late Box _box;

  HiveCache({this.boxName = 'persisto_cache'});

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
