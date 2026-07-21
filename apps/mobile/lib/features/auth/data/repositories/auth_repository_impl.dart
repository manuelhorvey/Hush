import '../../../../core/network/network_errors.dart';
import '../../../../core/storage/secure_storage.dart';
import '../datasources/auth_remote_datasource.dart';

class SessionInfo {
  final String token;
  final String userId;
  final String username;

  const SessionInfo({
    required this.token,
    required this.userId,
    required this.username,
  });
}

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

  Future<SessionInfo> register({
    required String username,
    required String publicKey,
  }) async {
    try {
      final response = await _remoteDataSource.register(username, publicKey);
      await _saveSession(response.token, response.refreshToken,
          response.userId, response.username);
      return SessionInfo(
        token: response.token,
        userId: response.userId,
        username: response.username,
      );
    } on NetworkException {
      rethrow;
    }
  }

  Future<SessionInfo> login({required String username}) async {
    try {
      final response = await _remoteDataSource.login(username);
      await _saveSession(response.token, response.refreshToken,
          response.userId, response.username);
      return SessionInfo(
        token: response.token,
        userId: response.userId,
        username: response.username,
      );
    } on NetworkException {
      rethrow;
    }
  }

  Future<SessionInfo?> tryRestoreSession() async {
    final token = await _storage.getAuthToken();
    if (token == null) return null;

    try {
      final response = await _remoteDataSource.getSession();
      if (response.token.isNotEmpty) {
        await _saveSession(response.token, response.refreshToken,
            response.userId, response.username);
      }
      return SessionInfo(
        token: response.token.isNotEmpty ? response.token : token,
        userId: response.userId,
        username: response.username,
      );
    } on NetworkException {
      final userId = await _storage.getUserId();
      final username = await _storage.getUsername();
      if (userId != null && username != null) {
        return SessionInfo(token: token, userId: userId, username: username);
      }
      await _storage.clearSession();
      return null;
    }
  }

  Future<String?> refreshToken() async {
    final refresh = await _storage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return null;
    try {
      final response = await _remoteDataSource.refreshToken(refresh);
      await _storage.saveAuthToken(response.token);
      if (response.refreshToken.isNotEmpty) {
        await _storage.saveRefreshToken(response.refreshToken);
      }
      return response.token;
    } on NetworkException {
      return null;
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
