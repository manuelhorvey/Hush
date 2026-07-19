import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> get(String path, {required String token}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ApiException(
      response.statusCode,
      body['error'] as String? ?? 'Unknown error',
    );
  }
}
