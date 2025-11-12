import 'dart:convert';

import 'package:http/http.dart' as http;

import 'adapter_interface.dart';

class HttpAdapter implements DataAdapter {
  final String baseUrl;
  final Map<String, String>? headers;

  HttpAdapter({required this.baseUrl, this.headers});

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);
    return jsonDecode(response.body);
  }

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  @override
  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  @override
  Future<dynamic> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  @override
  Stream<dynamic>? listen(String path) => null;
}

