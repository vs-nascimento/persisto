import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'cache_interface.dart';

/// Cache implementation backed by a Sqflite database.
///
/// Provide an absolute [databasePath] to open/create the database. The adapter
/// creates a single table storing JSON-encoded payloads and timestamps.
class SqfliteCache implements CacheStorage {
  /// Creates a cache stored in a Sqflite database.
  SqfliteCache({
    required this.databasePath,
    this.tableName = 'persisto_cache',
    DatabaseFactory? factory,
  }) : _databaseFactory = factory ?? databaseFactory;

  /// Fully qualified path to the Sqflite database file.
  final String databasePath;

  /// Table name used to store cache entries.
  final String tableName;

  final DatabaseFactory _databaseFactory;
  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    _database = await _databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $tableName (
              key TEXT PRIMARY KEY,
              payload TEXT NOT NULL
            )
            ''');
        },
      ),
    );
    return _database!;
  }

  @override
  Future<void> write(String key, dynamic value) async {
    final db = await _db;
    await db.insert(tableName, {
      'key': key,
      'payload': jsonEncode({
        'data': value,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<dynamic> read(String key) async {
    final db = await _db;
    final result = await db.query(
      tableName,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isEmpty) return null;
    final payload = result.first['payload'] as String?;
    if (payload == null) return null;
    return jsonDecode(payload);
  }

  @override
  Future<void> delete(String key) async {
    final db = await _db;
    await db.delete(tableName, where: 'key = ?', whereArgs: [key]);
  }

  @override
  Future<void> clear() async {
    final db = await _db;
    await db.delete(tableName);
  }

  /// Closes the underlying database instance.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
