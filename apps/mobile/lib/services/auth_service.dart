// ignore_for_file: prefer_initializing_formals

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class SessionInfo {
  final String userId;
  final String username;
  final String token;

  SessionInfo({
    required this.userId,
    required this.username,
    required this.token,
  });
}

class AuthService {
  final ApiClient _api;
  final FlutterSecureStorage _storage;

  AuthService({required ApiClient api, FlutterSecureStorage? storage})
      : _api = api,
        _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'session_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'username';

  Future<String?> get token async => _storage.read(key: _tokenKey);

  Future<SessionInfo> register(String username, String publicKey) async {
    final data = await _api.post('/api/v1/auth/register', {
      'username': username,
      'public_key': publicKey,
    });

    final token = data['token'] as String;
    final userId = data['user_id'] as String;

    await _storeSession(token, userId, username);
    if (data['refresh_token'] != null) {
      await _storage.write(key: _refreshTokenKey, value: data['refresh_token'] as String);
    }

    return SessionInfo(token: token, userId: userId, username: username);
  }

  Future<SessionInfo> login(String username) async {
    final data = await _api.post('/api/v1/auth/login', {
      'username': username,
    });

    final token = data['token'] as String;
    final userId = data['user_id'] as String;

    await _storeSession(token, userId, username);
    if (data['refresh_token'] != null) {
      await _storage.write(key: _refreshTokenKey, value: data['refresh_token'] as String);
    }

    return SessionInfo(token: token, userId: userId, username: username);
  }

  Future<SessionInfo?> getSession() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;

    try {
      final data = await _api.get('/api/v1/auth/session', token: token);
      final userId = data['user_id'] as String;
      final username = data['username'] as String;
      return SessionInfo(token: token, userId: userId, username: username);
    } catch (_) {
      final refreshed = await _tryRefresh();
      if (refreshed != null) return refreshed;
      await clearSession();
      return null;
    }
  }

  Future<String?> refreshToken() async {
    return _tryRefresh().then((s) => s?.token);
  }

  Future<SessionInfo?> _tryRefresh() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return null;
    try {
      final data = await _api.post('/api/v1/auth/refresh', {
        'refresh_token': refreshToken,
      });
      final newToken = data['token'] as String;
      await _storage.write(key: _tokenKey, value: newToken);
      if (data['refresh_token'] != null) {
        await _storage.write(key: _refreshTokenKey, value: data['refresh_token'] as String);
      }
      final userId = await _storage.read(key: _userIdKey) ?? '';
      final username = await _storage.read(key: _usernameKey) ?? '';
      return SessionInfo(token: newToken, userId: userId, username: username);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _usernameKey);
  }

  Future<void> _storeSession(
      String token, String userId, String username) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _usernameKey, value: username);
  }
}
