import 'package:supabase_flutter/supabase_flutter.dart';

import 'adapter_interface.dart';

/// Signature used to customize Supabase `PostgrestFilterBuilder` queries.
typedef SupabaseQueryBuilder = dynamic Function(dynamic query);

/// Supabase adapter backed by `supabase_flutter`.
class SupabaseAdapter implements DataAdapter {
  /// Creates a new adapter targeting [table] with the provided [client].
  SupabaseAdapter({
    required this.client,
    required this.table,
    this.primaryKey = 'id',
    this.queryBuilder,
  });

  /// Supabase client instance.
  final SupabaseClient client;

  /// Table name used for operations.
  final String table;

  /// Column used as unique identifier for `get`/`put`/`delete` operations.
  final String primaryKey;

  /// Optional default query override.
  final SupabaseQueryBuilder? queryBuilder;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    final SupabaseQueryBuilder? builder =
        (params?['queryBuilder'] as SupabaseQueryBuilder?) ?? queryBuilder;

    if (path.isEmpty) {
      dynamic query = client.from(table).select();
      if (builder != null) {
        query = builder(query);
      }
      return await query;
    } else {
      return await client
          .from(table)
          .select()
          .eq(primaryKey, path)
          .maybeSingle();
    }
  }

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    return await client.from(table).insert(body).select().maybeSingle();
  }

  @override
  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    if (path.isEmpty) {
      throw ArgumentError(
        'Primary key value is required for SupabaseAdapter.put',
      );
    }
    return await client
        .from(table)
        .update(body)
        .eq(primaryKey, path)
        .select()
        .maybeSingle();
  }

  @override
  Future<dynamic> delete(String path) async {
    if (path.isEmpty) {
      throw ArgumentError(
        'Primary key value is required for SupabaseAdapter.delete',
      );
    }
    await client.from(table).delete().eq(primaryKey, path);
    return {'id': path, 'deleted': true};
  }

  @override
  Stream<dynamic>? listen(String path) {
    final stream = client.from(table).stream(primaryKey: [primaryKey]);
    if (path.isEmpty) {
      return stream;
    }
    return stream.map((rows) {
      final match = rows.cast<Map<String, dynamic>>().where(
        (row) => row[primaryKey] == path,
      );
      if (match.isEmpty) return null;
      return match.first;
    });
  }
}
