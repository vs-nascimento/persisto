import 'package:dio/dio.dart';

import 'adapter_interface.dart';

class DioAdapter implements DataAdapter {
  DioAdapter({
    Dio? dio,
    String baseUrl = '',
    Map<String, dynamic>? headers,
    Map<String, dynamic>? defaultQueryParameters,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               headers: headers,
               queryParameters: defaultQueryParameters,
               responseType: ResponseType.json,
             ),
           );

  final Dio _dio;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    final response = await _dio.get<dynamic>(path, queryParameters: params);
    return response.data;
  }

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await _dio.post<dynamic>(path, data: body);
    return response.data;
  }

  @override
  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final response = await _dio.put<dynamic>(path, data: body);
    return response.data;
  }

  @override
  Future<dynamic> delete(String path) async {
    final response = await _dio.delete<dynamic>(path);
    return response.data;
  }

  @override
  Stream<dynamic>? listen(String path) => null;
}
