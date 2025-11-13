/// Contract for network/client adapters that the interceptor can use.
///
/// Implement this interface to plug in custom data sources (REST, gRPC, etc.).
abstract class DataAdapter {
  /// Fetches data from [path] using an optional map of query [params].
  Future<dynamic> get(String path, {Map<String, dynamic>? params});

  /// Sends a POST request to [path] with the provided [body].
  Future<dynamic> post(String path, Map<String, dynamic> body);

  /// Sends a PUT request to [path] with the provided [body].
  Future<dynamic> put(String path, Map<String, dynamic> body);

  /// Sends a DELETE request to [path].
  Future<dynamic> delete(String path);

  /// (Optional) subscribes to realtime updates for [path].
  Stream<dynamic>? listen(String path);
}
