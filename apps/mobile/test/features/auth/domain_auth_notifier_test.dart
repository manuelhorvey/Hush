import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/auth/domain/entities/auth_state.dart';
import 'package:hush_mobile/features/auth/domain/entities/user_session.dart';
import 'package:hush_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:hush_mobile/features/auth/presentation/providers/auth_state_provider.dart';

// ═══════════════════════════════════════════════════════════════
// Mock AuthRepository
// ═══════════════════════════════════════════════════════════════

class MockAuthRepository implements AuthRepository {
  UserSession? _session;
  bool _shouldThrowOnInit = false;
  bool _shouldThrowOnRegister = false;
  bool _shouldThrowOnLogin = false;
  AuthState _restoreResult = const AuthUnauthenticated();
  AuthState _registerResult = const AuthAuthenticated(
    token: 'reg-token',
    userId: 'reg-user',
    username: 'reg-user',
    deviceId: 'reg-device',
  );
  AuthState _loginResult = const AuthAuthenticated(
    token: 'login-token',
    userId: 'login-user',
    username: 'login-user',
    deviceId: 'login-device',
  );
  AuthState _refreshResult = const AuthExpired();

  void setRestoreResult(AuthState result) => _restoreResult = result;
  void setRegisterResult(AuthState result) => _registerResult = result;
  void setLoginResult(AuthState result) => _loginResult = result;
  void setRefreshResult(AuthState result) => _refreshResult = result;
  void setThrowOnInit() => _shouldThrowOnInit = true;
  void setThrowOnRegister() => _shouldThrowOnRegister = true;
  void setThrowOnLogin() => _shouldThrowOnLogin = true;

  void setSession(UserSession? session) => _session = session;

  @override
  Future<AuthState> restoreSession() async {
    if (_shouldThrowOnInit) throw Exception('Network error');
    return _restoreResult;
  }

  @override
  Future<AuthState> register({
    required String username,
    required String publicKey,
  }) async {
    if (_shouldThrowOnRegister) throw Exception('Registration failed');
    return _registerResult;
  }

  @override
  Future<AuthState> login({required String username}) async {
    if (_shouldThrowOnLogin) throw Exception('Login failed');
    return _loginResult;
  }

  @override
  Future<void> logout() async {
    _session = null;
  }

  @override
  Future<AuthState> refreshSession() async {
    return _refreshResult;
  }

  @override
  UserSession? get currentSession => _session;

  @override
  bool get hasActiveSession => _session?.isValid ?? false;
}

// ═══════════════════════════════════════════════════════════════
// Test helpers
// ═══════════════════════════════════════════════════════════════

ProviderContainer createContainer({
  required MockAuthRepository mockRepo,
}) {
  return ProviderContainer(
    overrides: [
      domainAuthRepositoryProvider.overrideWithValue(mockRepo),
    ],
  );
}

void main() {
  group('DomainAuthStateNotifier — init()', () {
    test('starts as AuthUnknown', () {
      final mock = MockAuthRepository();
      final container = createContainer(mockRepo: mock);
      final state = container.read(domainAuthStateProvider);
      expect(state, const AuthUnknown());
    });

    test('transitions through Authenticating → Authenticated when session restored', () async {
      final mock = MockAuthRepository();
      mock.setRestoreResult(const AuthAuthenticated(
        token: 'saved-token',
        userId: 'saved-user',
        username: 'saved-user',
        deviceId: 'saved-device',
      ));

      final container = createContainer(mockRepo: mock);
      await container.read(domainAuthStateProvider.notifier).init();

      final state = container.read(domainAuthStateProvider);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).token, 'saved-token');
      expect(state.userId, 'saved-user');
    });

    test('transitions through Authenticating → Unauthenticated when no session', () async {
      final mock = MockAuthRepository();
      mock.setRestoreResult(const AuthUnauthenticated());

      final container = createContainer(mockRepo: mock);
      await container.read(domainAuthStateProvider.notifier).init();

      final state = container.read(domainAuthStateProvider);
      expect(state, isA<AuthUnauthenticated>());
    });

    test('transitions to Unauthenticated on error', () async {
      final mock = MockAuthRepository();
      mock.setThrowOnInit();

      final container = createContainer(mockRepo: mock);
      await container.read(domainAuthStateProvider.notifier).init();

      final state = container.read(domainAuthStateProvider);
      expect(state, isA<AuthUnauthenticated>());
    });
  });

  group('DomainAuthStateNotifier — register()', () {
    test('transitions through Authenticating → Authenticated on success', () async {
      final mock = MockAuthRepository();
      final container = createContainer(mockRepo: mock);

      final result = await container.read(domainAuthStateProvider.notifier).register(
        username: 'alice',
        publicKey: 'abc123',
      );

      expect(result, isA<AuthAuthenticated>());
      final state = container.read(domainAuthStateProvider);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).username, 'reg-user');
    });

    test('transitions to Unauthenticated and rethrows on error', () async {
      final mock = MockAuthRepository();
      mock.setThrowOnRegister();
      final container = createContainer(mockRepo: mock);

      await expectLater(
        container.read(domainAuthStateProvider.notifier).register(
          username: 'alice',
          publicKey: 'abc123',
        ),
        throwsException,
      );

      final state = container.read(domainAuthStateProvider);
      expect(state, isA<AuthUnauthenticated>());
    });

    test('returns the AuthAuthenticated state from the repository', () async {
      final mock = MockAuthRepository();
      mock.setRegisterResult(const AuthAuthenticated(
        token: 'custom-token',
        userId: 'custom-user',
        username: 'CustomUser',
        deviceId: 'custom-device',
      ));
      final container = createContainer(mockRepo: mock);

      final result = await container.read(domainAuthStateProvider.notifier).register(
        username: 'bob',
        publicKey: 'xyz789',
      );

      expect(result, isA<AuthAuthenticated>());
      expect((result as AuthAuthenticated).username, 'CustomUser');
    });
  });

  group('DomainAuthStateNotifier — login()', () {
    test('transitions through Authenticating → Authenticated on success', () async {
      final mock = MockAuthRepository();
      final container = createContainer(mockRepo: mock);

      final result = await container.read(domainAuthStateProvider.notifier).login(
        username: 'alice',
      );

      expect(result, isA<AuthAuthenticated>());
      final state = container.read(domainAuthStateProvider);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).userId, 'login-user');
    });

    test('transitions to Unauthenticated and rethrows on error', () async {
      final mock = MockAuthRepository();
      mock.setThrowOnLogin();
      final container = createContainer(mockRepo: mock);

      await expectLater(
        container.read(domainAuthStateProvider.notifier).login(
          username: 'alice',
        ),
        throwsException,
      );

      final state = container.read(domainAuthStateProvider);
      expect(state, isA<AuthUnauthenticated>());
    });
  });

  group('DomainAuthStateNotifier — logout()', () {
    test('transitions to Unauthenticated', () async {
      final mock = MockAuthRepository();
      final container = createContainer(mockRepo: mock);

      // First login to set authenticated state
      await container.read(domainAuthStateProvider.notifier).login(
        username: 'alice',
      );

      // Then logout
      await container.read(domainAuthStateProvider.notifier).logout();

      final state = container.read(domainAuthStateProvider);
      expect(state, isA<AuthUnauthenticated>());
    });

    test('logout from unauthenticated stays unauthenticated', () async {
      final mock = MockAuthRepository();
      final container = createContainer(mockRepo: mock);

      await container.read(domainAuthStateProvider.notifier).logout();

      final state = container.read(domainAuthStateProvider);
      expect(state, isA<AuthUnauthenticated>());
    });
  });

  group('DomainAuthStateNotifier — refreshSession()', () {
    test('transitions to Expired when refresh fails', () async {
      final mock = MockAuthRepository();
      mock.setRefreshResult(const AuthExpired());
      final container = createContainer(mockRepo: mock);

      await container.read(domainAuthStateProvider.notifier).refreshSession();

      final state = container.read(domainAuthStateProvider);
      expect(state, isA<AuthExpired>());
    });

    test('transitions to Authenticated when refresh succeeds', () async {
      final mock = MockAuthRepository();
      mock.setRefreshResult(const AuthAuthenticated(
        token: 'refreshed-token',
        userId: 'user-1',
        username: 'alice',
        deviceId: 'device-1',
      ));
      final container = createContainer(mockRepo: mock);

      await container.read(domainAuthStateProvider.notifier).refreshSession();

      final state = container.read(domainAuthStateProvider);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).token, 'refreshed-token');
    });
  });

  group('DomainAuthStateNotifier — getters', () {
    test('userId returns null when not authenticated', () {
      final mock = MockAuthRepository();
      final container = createContainer(mockRepo: mock);
      final notifier = container.read(domainAuthStateProvider.notifier);
      expect(notifier.userId, isNull);
    });

    test('username returns null when not authenticated', () {
      final mock = MockAuthRepository();
      final container = createContainer(mockRepo: mock);
      final notifier = container.read(domainAuthStateProvider.notifier);
      expect(notifier.username, isNull);
    });

    test('token returns null when not authenticated', () {
      final mock = MockAuthRepository();
      final container = createContainer(mockRepo: mock);
      final notifier = container.read(domainAuthStateProvider.notifier);
      expect(notifier.token, isNull);
    });

    test('deviceId returns null when not authenticated', () {
      final mock = MockAuthRepository();
      final container = createContainer(mockRepo: mock);
      final notifier = container.read(domainAuthStateProvider.notifier);
      expect(notifier.deviceId, isNull);
    });

    test('returns correct values when authenticated', () async {
      final mock = MockAuthRepository();
      final container = createContainer(mockRepo: mock);
      final notifier = container.read(domainAuthStateProvider.notifier);

      await notifier.login(username: 'alice');

      expect(notifier.userId, 'login-user');
      expect(notifier.username, 'login-user');
      expect(notifier.token, 'login-token');
      expect(notifier.deviceId, 'login-device');
    });

    test('returns null after logout', () async {
      final mock = MockAuthRepository();
      final container = createContainer(mockRepo: mock);
      final notifier = container.read(domainAuthStateProvider.notifier);

      await notifier.login(username: 'alice');
      await notifier.logout();

      expect(notifier.userId, isNull);
      expect(notifier.username, isNull);
      expect(notifier.token, isNull);
      expect(notifier.deviceId, isNull);
    });
  });
}
