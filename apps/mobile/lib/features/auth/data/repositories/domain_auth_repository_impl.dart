import '../../../../core/network/network_errors.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/device_repository.dart';
import '../../domain/services/session_manager.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Domain-aware implementation of [AuthRepository].
///
/// Orchestrates remote API calls, local secure storage, and session
/// lifecycle management. Produces domain [AuthState] values directly
/// so the presentation layer never deals with raw tokens or session strings.
///
/// This coexists alongside the legacy `AuthRepository` in
/// `auth_repository_impl.dart` (which is used by existing screens).
/// New screens and providers should use this implementation.
class DomainAuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final SessionManager _sessionManager;

  DomainAuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required DeviceRepository deviceRepository,
    required SessionManager sessionManager,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _sessionManager = sessionManager;

  @override
  UserSession? get currentSession => _sessionManager.currentSession;

  @override
  bool get hasActiveSession => _sessionManager.hasActiveSession;

  @override
  Future<AuthState> restoreSession() async {
    try {
      final creds = await _localDataSource.readAllCredentials();

      if (creds.token == null) {
        return const AuthUnauthenticated();
      }

      // Try to validate the session with the server.
      try {
        final response = await _remoteDataSource.getSession();
        if (response.token.isNotEmpty) {
          await _localDataSource.saveSessionCredentials(
            token: response.token,
            refreshToken: response.refreshToken.isNotEmpty
                ? response.refreshToken
                : (creds.refreshToken ?? ''),
            userId: response.userId.isNotEmpty
                ? response.userId
                : (creds.userId ?? ''),
            username: response.username.isNotEmpty
                ? response.username
                : (creds.username ?? ''),
          );

          final session = _buildSession(
            token: response.token,
            userId: response.userId.isNotEmpty
                ? response.userId
                : (creds.userId ?? ''),
            username: response.username.isNotEmpty
                ? response.username
                : (creds.username ?? ''),
            deviceId: creds.deviceId ?? '',
          );
          _sessionManager.startSession(session);
          return AuthAuthenticated(
            token: response.token,
            userId: response.userId.isNotEmpty
                ? response.userId
                : (creds.userId ?? ''),
            username: response.username.isNotEmpty
                ? response.username
                : (creds.username ?? ''),
            deviceId: creds.deviceId ?? '',
          );
        }
      } on UnauthorizedException {
        final refreshed = await _tryRefresh(creds.refreshToken);
        if (refreshed != null) return refreshed;
        await _localDataSource.clearSession();
        return const AuthUnauthenticated();
      } on NetworkException {
        // Offline — use stored credentials if available.
        if (creds.userId != null && creds.username != null) {
          final session = _buildSession(
            token: creds.token!,
            userId: creds.userId!,
            username: creds.username!,
            deviceId: creds.deviceId ?? '',
          );
          _sessionManager.startSession(session);
          return AuthAuthenticated(
            token: creds.token!,
            userId: creds.userId!,
            username: creds.username!,
            deviceId: creds.deviceId ?? '',
          );
        }
        await _localDataSource.clearSession();
        return const AuthUnauthenticated();
      }

      if (creds.userId != null && creds.username != null) {
        final session = _buildSession(
          token: creds.token!,
          userId: creds.userId!,
          username: creds.username!,
          deviceId: creds.deviceId ?? '',
        );
        _sessionManager.startSession(session);
        return AuthAuthenticated(
          token: creds.token!,
          userId: creds.userId!,
          username: creds.username!,
          deviceId: creds.deviceId ?? '',
        );
      }

      await _localDataSource.clearSession();
      return const AuthUnauthenticated();
    } catch (_) {
      await _localDataSource.clearSession();
      return const AuthUnauthenticated();
    }
  }

  @override
  Future<AuthState> register({
    required String username,
    required String publicKey,
  }) async {
    try {
      final response = await _remoteDataSource.register(username, publicKey);
      final safeUsername =
          response.username.isNotEmpty ? response.username : username;
      final deviceId = response.userId;

      await _localDataSource.saveSessionCredentials(
        token: response.token,
        refreshToken: response.refreshToken,
        userId: response.userId,
        username: safeUsername,
      );

      if (deviceId.isNotEmpty) {
        await _localDataSource.saveDeviceId(deviceId);
      }

      final session = _buildSession(
        token: response.token,
        userId: response.userId,
        username: safeUsername,
        deviceId: deviceId,
      );
      _sessionManager.startSession(session);

      return AuthAuthenticated(
        token: response.token,
        userId: response.userId,
        username: safeUsername,
        deviceId: deviceId,
      );
    } on NetworkException {
      rethrow;
    }
  }

  @override
  Future<AuthState> login({required String username}) async {
    try {
      final response = await _remoteDataSource.login(username);
      final safeUsername =
          response.username.isNotEmpty ? response.username : username;

      await _localDataSource.saveSessionCredentials(
        token: response.token,
        refreshToken: response.refreshToken,
        userId: response.userId,
        username: safeUsername,
      );

      final deviceId = await _localDataSource.getDeviceId() ?? response.userId;

      final session = _buildSession(
        token: response.token,
        userId: response.userId,
        username: safeUsername,
        deviceId: deviceId,
      );
      _sessionManager.startSession(session);

      return AuthAuthenticated(
        token: response.token,
        userId: response.userId,
        username: safeUsername,
        deviceId: deviceId,
      );
    } on NetworkException {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    _sessionManager.endSession();
    try {
      await _remoteDataSource.logout();
    } catch (_) {}
    await _localDataSource.clearSession();
  }

  @override
  Future<AuthState> refreshSession() async {
    final refreshToken = await _localDataSource.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return const AuthExpired();
    }
    final result = await _tryRefresh(refreshToken);
    return result ?? const AuthExpired();
  }

  Future<AuthState?> _tryRefresh(String? refreshToken) async {
    if (refreshToken == null || refreshToken.isEmpty) return null;
    try {
      final response = await _remoteDataSource.refreshToken(refreshToken);
      if (response.token.isEmpty) return null;

      await _localDataSource.saveToken(response.token);
      if (response.refreshToken.isNotEmpty) {
        await _localDataSource.saveRefreshToken(response.refreshToken);
      }

      final userId = await _localDataSource.getUserId() ?? '';
      final username = await _localDataSource.getUsername() ?? '';
      final deviceId = await _localDataSource.getDeviceId() ?? '';

      final session = _buildSession(
        token: response.token,
        userId: userId,
        username: username,
        deviceId: deviceId,
      );
      _sessionManager.updateSession(session);

      return AuthAuthenticated(
        token: response.token,
        userId: userId,
        username: username,
        deviceId: deviceId,
      );
    } on NetworkException {
      return null;
    }
  }

  UserSession _buildSession({
    required String token,
    required String userId,
    required String username,
    required String deviceId,
  }) {
    return UserSession(
      sessionId: token.hashCode.toString(),
      userId: userId,
      username: username,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      deviceId: deviceId,
      status: SessionStatus.active,
    );
  }
}
