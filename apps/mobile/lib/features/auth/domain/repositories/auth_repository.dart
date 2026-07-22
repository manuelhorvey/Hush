import '../entities/user_session.dart';
import '../entities/auth_state.dart';

/// Abstract repository for authentication operations.
///
/// This is the single source of truth for session lifecycle.
/// Implementations handle persistence (secure storage), remote API calls,
/// and session validation.
abstract class AuthRepository {
  /// Check for and restore a stored session on app start.
  /// Returns [AuthState.authenticated] with session data, or
  /// [AuthState.unauthenticated] if no valid session exists.
  Future<AuthState> restoreSession();

  /// Register a new identity with the given [username] and [publicKey].
  /// Returns the authenticated state on success.
  Future<AuthState> register({
    required String username,
    required String publicKey,
  });

  /// Authenticate as an existing user with the given [username].
  /// Returns the authenticated state on success.
  Future<AuthState> login({required String username});

  /// End the current session and clear all stored credentials.
  Future<void> logout();

  /// Refresh the session token using the stored refresh token.
  /// Returns the new [AuthState] or [AuthState.expired] if refresh fails.
  Future<AuthState> refreshSession();

  /// Get the current session info, if available.
  UserSession? get currentSession;

  /// Whether a session is currently active.
  bool get hasActiveSession;
}
