abstract class DataAdapter {
  Future<dynamic> get(String path, {Map<String, dynamic>? params});

  Future<dynamic> post(String path, Map<String, dynamic> body);

  Future<dynamic> put(String path, Map<String, dynamic> body);

  Future<dynamic> delete(String path);

  Stream<dynamic>? listen(String path);
}

