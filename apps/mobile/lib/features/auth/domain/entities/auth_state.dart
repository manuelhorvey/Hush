/// Authentication states for the Hush session lifecycle.
///
/// Design principle: avoid unnecessary friction. States transition
/// naturally — the user should never feel stuck or surprised.
sealed class AuthState {
  const AuthState();

  /// Initial state — app just launched, checking for a stored session.
  const factory AuthState.unknown() = AuthUnknown;

  /// No active session — user needs to create or recover their identity.
  const factory AuthState.unauthenticated() = AuthUnauthenticated;

  /// Actively trying to authenticate (network request in flight).
  const factory AuthState.authenticating() = AuthAuthenticating;

  /// User has a valid, active session.
  const factory AuthState.authenticated({
    required String token,
    required String userId,
    required String username,
    required String deviceId,
  }) = AuthAuthenticated;

  /// Session has expired — user can re-authenticate without starting over.
  const factory AuthState.expired() = AuthExpired;

  /// Device has been locked (e.g. too many failed attempts, security check).
  const factory AuthState.locked() = AuthLocked;

  bool get isUnknown => this is AuthUnknown;
  bool get isUnauthenticated => this is AuthUnauthenticated;
  bool get isAuthenticating => this is AuthAuthenticating;
  bool get isAuthenticated => this is AuthAuthenticated;
  bool get isExpired => this is AuthExpired;
  bool get isLocked => this is AuthLocked;
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticating extends AuthState {
  const AuthAuthenticating();
}

class AuthAuthenticated extends AuthState {
  final String token;
  final String userId;
  final String username;
  final String deviceId;

  const AuthAuthenticated({
    required this.token,
    required this.userId,
    required this.username,
    required this.deviceId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthAuthenticated &&
          token == other.token &&
          userId == other.userId &&
          username == other.username &&
          deviceId == other.deviceId;

  @override
  int get hashCode => Object.hash(token, userId, username, deviceId);
}

class AuthExpired extends AuthState {
  const AuthExpired();
}

class AuthLocked extends AuthState {
  const AuthLocked();
}
