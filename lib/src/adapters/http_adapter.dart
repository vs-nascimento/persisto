import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/persisto_exception.dart';
import 'adapter_interface.dart';

/// Basic REST adapter built on top of `package:http`.
class HttpAdapter implements DataAdapter {
  /// Creates a new adapter pointing to [baseUrl] and optional [headers].
  HttpAdapter({required this.baseUrl, this.headers});

  /// Base endpoint used to build request URLs.
  final String baseUrl;

  /// Default headers used for every request.
  final Map<String, String>? headers;

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw AdapterException('Failed to parse response body as JSON', e);
      }
    }

    dynamic responseBody;
    try {
      responseBody = jsonDecode(response.body);
    } catch (_) {
      responseBody = response.body;
    }

    throw HttpException(
      'HTTP request failed: ${response.reasonPhrase ?? 'Unknown error'}',
      response.statusCode,
      responseBody: responseBody,
    );
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } on HttpException {
      rethrow;
    } on AdapterException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to execute GET request to $path', e);
    }
  }

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } on HttpException {
      rethrow;
    } on AdapterException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to execute POST request to $path', e);
    }
  }

  @override
  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } on HttpException {
      rethrow;
    } on AdapterException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to execute PUT request to $path', e);
    }
  }

  @override
  Future<dynamic> delete(String path) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: headers,
      );
      return _handleResponse(response);
    } on HttpException {
      rethrow;
    } on AdapterException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to execute DELETE request to $path', e);
    }
  }

  @override
  Stream<dynamic>? listen(String path) => null;
}
