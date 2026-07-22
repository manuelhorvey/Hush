import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/auth/domain/entities/user_session.dart';

void main() {
  group('UserSession — domain entity', () {
    final now = DateTime.now();
    final futureDate = now.add(const Duration(days: 30));
    final pastDate = now.subtract(const Duration(days: 1));

    test('active session — isValid returns true', () {
      final session = UserSession(
        sessionId: 'ses-1',
        userId: 'user-1',
        username: 'alice',
        createdAt: now,
        expiresAt: futureDate,
        deviceId: 'device-1',
        status: SessionStatus.active,
      );

      expect(session.isValid, isTrue);
      expect(session.isExpired, isFalse);
      expect(session.isAboutToExpire, isFalse);
    });

    test('expired session — isValid returns false', () {
      final session = UserSession(
        sessionId: 'ses-2',
        userId: 'user-1',
        username: 'alice',
        createdAt: pastDate,
        expiresAt: pastDate,
        deviceId: 'device-1',
        status: SessionStatus.expired,
      );

      expect(session.isValid, isFalse);
      expect(session.isExpired, isTrue);
    });

    test('revoked session — isValid returns false', () {
      final session = UserSession(
        sessionId: 'ses-3',
        userId: 'user-1',
        username: 'alice',
        createdAt: now,
        expiresAt: futureDate,
        deviceId: 'device-1',
        status: SessionStatus.revoked,
      );

      expect(session.isValid, isFalse);
      expect(session.status.isRevoked, isTrue);
    });

    test('about to expire — within 5 minutes', () {
      final almostExpired = now.add(const Duration(minutes: 3));
      final session = UserSession(
        sessionId: 'ses-4',
        userId: 'user-1',
        username: 'alice',
        createdAt: now,
        expiresAt: almostExpired,
        deviceId: 'device-1',
        status: SessionStatus.active,
      );

      expect(session.isAboutToExpire, isTrue);
    });

    test('copyWith — preserves unchanged fields', () {
      final session = UserSession(
        sessionId: 'ses-1',
        userId: 'user-1',
        username: 'alice',
        createdAt: now,
        expiresAt: futureDate,
        deviceId: 'device-1',
        status: SessionStatus.active,
      );

      final updated = session.copyWith(status: SessionStatus.expired);

      expect(updated.status, equals(SessionStatus.expired));
      expect(updated.sessionId, equals('ses-1'));
      expect(updated.userId, equals('user-1'));
      expect(updated.username, equals('alice'));
    });

    test('displayId — truncates long session IDs', () {
      final session = UserSession(
        sessionId: 'abcd1234efgh5678',
        userId: 'user-1',
        username: 'alice',
        createdAt: now,
        expiresAt: futureDate,
        deviceId: 'device-1',
        status: SessionStatus.active,
      );

      expect(session.displayId.length, lessThan('abcd1234efgh5678'.length));
    });
  });
}
