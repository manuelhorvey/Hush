/// A user session — the result of a successful authentication.
///
/// Represents a validated, time-bound session bound to a specific device.
/// Sensitive values (token, refresh token) are never exposed to the UI layer.
class UserSession {
  final String sessionId;
  final String userId;
  final String username;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String deviceId;
  final SessionStatus status;

  const UserSession({
    required this.sessionId,
    required this.userId,
    required this.username,
    required this.createdAt,
    required this.expiresAt,
    required this.deviceId,
    required this.status,
  });

  bool get isValid => status == SessionStatus.active && !isExpired;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isAboutToExpire =>
      !isExpired &&
      expiresAt.difference(DateTime.now()).inMinutes < 5;

  UserSession copyWith({
    String? sessionId,
    String? userId,
    String? username,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? deviceId,
    SessionStatus? status,
  }) {
    return UserSession(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      deviceId: deviceId ?? this.deviceId,
      status: status ?? this.status,
    );
  }

  /// Truncated session ID for display purposes (e.g., "ses_...a1b2").
  String get displayId =>
      sessionId.length > 8
          ? '${sessionId.substring(0, 4)}...${sessionId.substring(sessionId.length - 4)}'
          : sessionId;
}

enum SessionStatus {
  /// Session is active and valid.
  active,

  /// Session has expired naturally.
  expired,

  /// Session was revoked (e.g., user logged out or remote device removal).
  revoked,

  /// Session is pending verification (e.g., new device needs confirmation).
  pending;

  bool get isActive => this == active;
  bool get isRevoked => this == revoked;
  bool get isExpiredOrRevoked => this == expired || this == revoked;
}
