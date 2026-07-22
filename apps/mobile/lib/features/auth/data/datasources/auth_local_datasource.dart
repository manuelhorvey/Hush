import 'package:flutter/foundation.dart';
import '../../../../core/storage/secure_storage.dart';

/// Local persistence layer for authentication credentials.
///
/// Stores only what's necessary for session recovery:
/// - Session token
/// - Refresh token
/// - User ID
/// - Username
/// - Device ID
///
/// Never stores: messages, conversation content, private keys.
class AuthLocalDataSource {
  final SecureStorageService _storage;

  AuthLocalDataSource({required SecureStorageService storage})
      : _storage = storage;

  // -- Token --

  Future<void> saveToken(String token) => _storage.saveAuthToken(token);
  Future<String?> getToken() => _storage.getAuthToken();

  // -- Refresh token --

  Future<void> saveRefreshToken(String token) =>
      _storage.saveRefreshToken(token);
  Future<String?> getRefreshToken() => _storage.getRefreshToken();

  // -- User ID --

  Future<void> saveUserId(String userId) => _storage.saveUserId(userId);
  Future<String?> getUserId() => _storage.getUserId();

  // -- Username --

  Future<void> saveUsername(String username) =>
      _storage.saveUsername(username);
  Future<String?> getUsername() => _storage.getUsername();

  // -- Device ID --

  Future<void> saveDeviceId(String deviceId) =>
      _storage.saveDeviceId(deviceId);
  Future<String?> getDeviceId() => _storage.getDeviceId();

  // -- Bulk operations --

  /// Save all session credentials at once.
  Future<void> saveSessionCredentials({
    required String token,
    required String refreshToken,
    required String userId,
    required String username,
  }) async {
    await Future.wait([
      _storage.saveAuthToken(token),
      _storage.saveRefreshToken(refreshToken),
      _storage.saveUserId(userId),
      _storage.saveUsername(username),
    ]);
  }

  /// Read all stored credentials. Any of these may be null.
  Future<({
    String? token,
    String? refreshToken,
    String? userId,
    String? username,
    String? deviceId,
  })> readAllCredentials() async {
    final results = await Future.wait([
      _storage.getAuthToken(),
      _storage.getRefreshToken(),
      _storage.getUserId(),
      _storage.getUsername(),
      _storage.getDeviceId(),
    ]);
    return (
      token: results[0] as String?,
      refreshToken: results[1] as String?,
      userId: results[2] as String?,
      username: results[3] as String?,
      deviceId: results[4] as String?,
    );
  }

  /// Clear all session credentials (logout).
  Future<void> clearSession() => _storage.clearSession();

  /// Clear everything (factory reset).
  Future<void> clearAll() => _storage.clearAll();
}
