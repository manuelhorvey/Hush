import '../../../../core/network/network_errors.dart';
import '../../../../core/storage/secure_storage.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _storage;

  AuthRepository({
    required this._remoteDataSource,
    required this._storage,
  });

  Future<bool> isLoggedIn() async {
    final token = await _storage.getAuthToken();
    return token != null;
  }

  Future<String?> getToken() async {
    return _storage.getAuthToken();
  }

  Future<String?> getUserId() async {
    return _storage.getUserId();
  }

  Future<String?> getUsername() async {
    return _storage.getUsername();
  }

  Future<void> register({
    required String username,
    required String publicKey,
  }) async {
    try {
      final response = await _remoteDataSource.register(username, publicKey);
      await _saveSession(response.token, response.refreshToken,
          response.userId, response.username);
    } on NetworkException {
      rethrow;
    }
  }

  Future<void> login({required String username}) async {
    try {
      final response = await _remoteDataSource.login(username);
      await _saveSession(response.token, response.refreshToken,
          response.userId, response.username);
    } on NetworkException {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.clearSession();
  }

  Future<void> _saveSession(
    String token,
    String refreshToken,
    String userId,
    String username,
  ) async {
    await Future.wait([
      _storage.saveAuthToken(token),
      _storage.saveRefreshToken(refreshToken),
      _storage.saveUserId(userId),
      _storage.saveUsername(username),
    ]);
  }
}
