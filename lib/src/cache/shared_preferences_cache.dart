import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'cache_interface.dart';

/// Cache implementation backed by `SharedPreferences`.
///
/// Each entry is stored as a JSON-encoded payload under `[prefix]::key`.
class SharedPreferencesCache implements CacheStorage {
  /// Creates a cache that uses [prefix] to namespace stored keys.
  SharedPreferencesCache({this.prefix = 'persisto'});

  /// Optional prefix applied to every stored key.
  final String prefix;

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String _namespaced(String key) => '$prefix::$key';

  @override
  Future<void> write(String key, dynamic value) async {
    final prefs = await _prefs;
    await prefs.setString(
      _namespaced(key),
      jsonEncode({
        'data': value,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }),
    );
  }

  @override
  Future<dynamic> read(String key) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_namespaced(key));
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  @override
  Future<void> delete(String key) async {
    final prefs = await _prefs;
    await prefs.remove(_namespaced(key));
  }

  @override
  Future<void> clear() async {
    final prefs = await _prefs;
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith('$prefix::'))
        .toList(growable: false);
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
