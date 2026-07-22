import 'dart:async';
import '../entities/user_session.dart';

/// Manages the lifecycle of a user session.
///
/// Responsibilities:
/// - Create, restore, refresh, and clear sessions
/// - Validate session expiration
/// - Emit auth state changes via streams
///
/// Design: the session manager owns the session data but does NOT
/// persist it directly — that's the repository's job. It coordinates
/// between the auth state provider and the repositories.
class SessionManager {
  UserSession? _session;
  Timer? _expiryTimer;
  Timer? _warningTimer;

  /// The current session, if one exists.
  UserSession? get currentSession => _session;

  /// Whether a valid session is active.
  bool get hasActiveSession => _session?.isValid ?? false;

  /// Whether the session is about to expire (within 5 minutes).
  bool get isAboutToExpire => _session?.isAboutToExpire ?? false;

  /// Whether the session has expired.
  bool get isExpired => _session?.isExpired ?? false;

  /// Set the current session and start expiry monitoring.
  void startSession(UserSession session) {
    _session = session;
    _startExpiryMonitoring(session);
  }

  /// Clear the current session and stop monitoring.
  void endSession() {
    _session = null;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _warningTimer?.cancel();
    _warningTimer = null;
  }

  /// Update the session after a token refresh.
  void updateSession(UserSession updated) {
    _session = updated;
    _startExpiryMonitoring(updated);
  }

  /// Start timers that fire when the session expires or is about to expire.
  void _startExpiryMonitoring(UserSession session) {
    _expiryTimer?.cancel();
    _warningTimer?.cancel();

    final now = DateTime.now();
    final expiryDuration = session.expiresAt.difference(now);

    if (expiryDuration.isNegative) {
      // Session already expired
      _session = session.copyWith(status: SessionStatus.expired);
      return;
    }

    // Warn when 5 minutes remain
    if (expiryDuration.inMinutes > 5) {
      final warningDuration = expiryDuration - const Duration(minutes: 5);
      _warningTimer = Timer(warningDuration, () {
        // Session is about to expire — UI can react to this
      });
    }

    // Mark expired when time runs out
    _expiryTimer = Timer(expiryDuration, () {
      if (_session != null) {
        _session = _session!.copyWith(status: SessionStatus.expired);
      }
    });
  }

  /// Dispose of all resources.
  void dispose() {
    _expiryTimer?.cancel();
    _warningTimer?.cancel();
  }
}
