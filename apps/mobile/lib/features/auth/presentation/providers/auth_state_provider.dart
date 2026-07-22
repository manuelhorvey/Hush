import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/api_client.dart';
import '../../../../services/identity_service.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/auth_providers.dart';
import '../../data/repositories/domain_auth_repository_impl.dart';
import '../../data/repositories/device_repository_impl.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/device_repository.dart';
import '../../domain/services/session_manager.dart';

// ═══════════════════════════════════════════════════════════════
// New auth architecture providers
// ───────────────────────────────────────────────────────────────
// These coexist with the legacy providers in core/providers/ and
// features/auth/data/. The legacy provider names (authStateProvider,
// authRepositoryProvider, apiClientProvider, secureStorageServiceProvider)
// remain unchanged to avoid breaking existing code.
//
// New screens should use `domainAuthStateProvider` for the sealed
// AuthState model and the new domain-aware repository.
// ═══════════════════════════════════════════════════════════════

/// New domain-aware [AuthLocalDataSource].
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  throw UnimplementedError('AuthLocalDataSource must be overridden in ProviderScope');
});

/// New domain-aware [SessionManager].
final sessionManagerProvider = Provider<SessionManager>((ref) {
  return SessionManager();
});

/// New domain-aware [DeviceRepository].
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepositoryImpl(
    identityService: ref.watch(identityServiceProvider),
  );
});

/// Legacy [IdentityService] provider (required by DeviceRepository).
final identityServiceProvider = Provider<IdentityService>((ref) {
  throw UnimplementedError('IdentityService must be overridden in ProviderScope');
});

/// Legacy [ApiClient] for identity/messaging services.
final legacyApiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError('legacyApiClient must be overridden in ProviderScope');
});

/// New domain-aware [AuthRepository] implementation.
final domainAuthRepositoryProvider = Provider<AuthRepository>((ref) {
  return DomainAuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
    deviceRepository: ref.watch(deviceRepositoryProvider),
    sessionManager: ref.watch(sessionManagerProvider),
  );
});

// ═══════════════════════════════════════════════════════════════
// Domain Auth State Notifier
// ═══════════════════════════════════════════════════════════════

/// Riverpod Notifier that manages the domain [AuthState].
///
/// This is the new, clean-architecture replacement for the legacy
/// AuthState notifier in `core/providers/auth_state_provider.dart`.
/// Use it in new screens; the legacy one remains for existing screens.
class DomainAuthStateNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthUnknown();

  AuthRepository get _repo => ref.read(domainAuthRepositoryProvider);

  /// Initialize auth state on app launch. Checks for existing session.
  Future<void> init() async {
    state = const AuthAuthenticating();
    try {
      state = await _repo.restoreSession();
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  /// Register a new identity.
  Future<AuthState> register({
    required String username,
    required String publicKey,
  }) async {
    state = const AuthAuthenticating();
    try {
      state = await _repo.register(username: username, publicKey: publicKey);
      return state;
    } catch (e) {
      state = const AuthUnauthenticated();
      rethrow;
    }
  }

  /// Login as an existing user.
  Future<AuthState> login({required String username}) async {
    state = const AuthAuthenticating();
    try {
      state = await _repo.login(username: username);
      return state;
    } catch (e) {
      state = const AuthUnauthenticated();
      rethrow;
    }
  }

  /// Logout — clear session, end session lifecycle.
  Future<void> logout() async {
    await _repo.logout();
    state = const AuthUnauthenticated();
  }

  /// Attempt to refresh the session token.
  Future<void> refreshSession() async {
    state = await _repo.refreshSession();
  }

  /// Get the current authenticated user's info, if any.
  String? get userId {
    final s = state;
    if (s is AuthAuthenticated) return s.userId;
    return null;
  }

  String? get username {
    final s = state;
    if (s is AuthAuthenticated) return s.username;
    return null;
  }

  String? get token {
    final s = state;
    if (s is AuthAuthenticated) return s.token;
    return null;
  }

  String? get deviceId {
    final s = state;
    if (s is AuthAuthenticated) return s.deviceId;
    return null;
  }
}

/// New domain-aware auth state provider.
/// Use this in new screens; the legacy `authStateProvider` remains for backwards compat.
final domainAuthStateProvider =
    NotifierProvider<DomainAuthStateNotifier, AuthState>(
  DomainAuthStateNotifier.new,
);
