import 'package:dio/dio.dart';

import '../core/persisto_exception.dart';
import 'adapter_interface.dart';

/// REST adapter backed by the Dio HTTP client.
class DioAdapter implements DataAdapter {
  /// Creates a new Dio adapter.
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

  /// Underlying Dio client.
  final Dio _dio;

  Future<dynamic> _handleRequest(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        // HTTP error with response
        throw HttpException(
          'HTTP request failed: ${e.response?.statusMessage ?? 'Unknown error'}',
          e.response!.statusCode ?? 0,
          responseBody: e.response?.data,
          cause: e,
        );
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        // Timeout error
        throw NetworkException(
          'Request timeout: ${e.message ?? 'Unknown timeout error'}',
          e,
        );
      } else if (e.type == DioExceptionType.connectionError) {
        // Connection error
        throw NetworkException(
          'Connection error: ${e.message ?? 'Failed to connect to server'}',
          e,
        );
      } else {
        // Other network errors
        throw NetworkException(
          'Network error: ${e.message ?? 'Unknown network error'}',
          e,
        );
      }
    } catch (e) {
      if (e is PersistoException) {
        rethrow;
      }
      throw AdapterException(
        'Unexpected error in DioAdapter',
        e,
      );
    }
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    return _handleRequest(() => _dio.get<dynamic>(path, queryParameters: params));
  }

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    return _handleRequest(() => _dio.post<dynamic>(path, data: body));
  }

  @override
  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    return _handleRequest(() => _dio.put<dynamic>(path, data: body));
  }

  @override
  Future<dynamic> delete(String path) async {
    return _handleRequest(() => _dio.delete<dynamic>(path));
  }

  @override
  Stream<dynamic>? listen(String path) => null;
}
