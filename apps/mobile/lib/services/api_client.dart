import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

String get apiHost {
  if (defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2';
  return 'localhost';
}

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
  Future<String?> Function()? onRefreshToken;

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

    return await _handleResponse(response, token: token, requestFn: (t) async {
      return _client.post(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $t'},
        body: jsonEncode(body),
      );
    });
  }

  Future<Map<String, dynamic>> get(String path, {required String token}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return await _handleResponse(response, token: token, requestFn: (t) async {
      return _client.get(Uri.parse('$baseUrl$path'), headers: {'Authorization': 'Bearer $t'});
    });
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    required String token,
  }) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return await _handleResponse(response, token: token, requestFn: (t) async {
      return _client.patch(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $t',
        },
        body: jsonEncode(body),
      );
    });
  }

  Future<void> delete(String path, {required String token}) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl$path'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401 && onRefreshToken != null) {
        final newToken = await onRefreshToken!();
        if (newToken != null) {
          final retry = await _client.delete(
            Uri.parse('$baseUrl$path'),
            headers: {'Authorization': 'Bearer $newToken'},
          );
          if (retry.statusCode >= 200 && retry.statusCode < 300) return;
          final body = jsonDecode(retry.body) as Map<String, dynamic>;
          throw ApiException(retry.statusCode, body['error'] as String? ?? 'Unknown error');
        }
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        response.statusCode,
        body['error'] as String? ?? 'Unknown error',
      );
    }
  }

  Future<Map<String, dynamic>> _handleResponse(
    http.Response response, {
    String? token,
    Future<http.Response> Function(String token)? requestFn,
  }) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 401 &&
        onRefreshToken != null &&
        requestFn != null &&
        token != null) {
      final newToken = await onRefreshToken!();
      if (newToken != null) {
        final retryResponse = await requestFn(newToken);
        if (retryResponse.statusCode >= 200 && retryResponse.statusCode < 300) {
          return jsonDecode(retryResponse.body) as Map<String, dynamic>;
        }
      }
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    throw ApiException(
      response.statusCode,
      body['error'] as String? ?? 'Unknown error',
    );
  }
}
