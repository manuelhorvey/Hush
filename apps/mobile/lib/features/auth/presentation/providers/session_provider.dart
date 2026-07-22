import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_session.dart';
import '../../domain/services/session_manager.dart';
import 'auth_state_provider.dart';

/// Provides access to the current [UserSession] for UI elements that
/// need session details (e.g., session status card, settings screen).
///
/// This is a derived provider that reads from the session manager.
final sessionProvider = Provider<UserSession?>((ref) {
  final manager = ref.watch(sessionManagerProvider);
  return manager.currentSession;
});

/// Whether the session is active and valid.
final sessionActiveProvider = Provider<bool>((ref) {
  final manager = ref.watch(sessionManagerProvider);
  return manager.hasActiveSession;
});

/// Whether the session is about to expire (within 5 minutes).
final sessionExpiringProvider = Provider<bool>((ref) {
  final manager = ref.watch(sessionManagerProvider);
  return manager.isAboutToExpire;
});

/// Whether the session has expired.
final sessionExpiredProvider = Provider<bool>((ref) {
  final manager = ref.watch(sessionManagerProvider);
  return manager.isExpired;
});
