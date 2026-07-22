import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/auth/domain/entities/auth_state.dart';

void main() {
  group('AuthState — domain entity', () {
    test('AuthUnknown — isUnknown returns true', () {
      final state = const AuthUnknown();
      expect(state.isUnknown, isTrue);
      expect(state.isUnauthenticated, isFalse);
      expect(state.isAuthenticated, isFalse);
      expect(state.isExpired, isFalse);
      expect(state.isLocked, isFalse);
    });

    test('AuthUnauthenticated — isUnauthenticated returns true', () {
      final state = const AuthUnauthenticated();
      expect(state.isUnauthenticated, isTrue);
      expect(state.isUnknown, isFalse);
      expect(state.isAuthenticated, isFalse);
    });

    test('AuthAuthenticating — isAuthenticating returns true', () {
      final state = const AuthAuthenticating();
      expect(state.isAuthenticating, isTrue);
      expect(state.isAuthenticated, isFalse);
    });

    test('AuthAuthenticated — holds correct values', () {
      final state = const AuthAuthenticated(
        token: 'test-token',
        userId: 'user-1',
        username: 'alice',
        deviceId: 'device-1',
      );

      expect(state.isAuthenticated, isTrue);
      expect(state.token, equals('test-token'));
      expect(state.userId, equals('user-1'));
      expect(state.username, equals('alice'));
      expect(state.deviceId, equals('device-1'));
    });

    test('AuthAuthenticated — equality works', () {
      final a = const AuthAuthenticated(
        token: 't1', userId: 'u1', username: 'alice', deviceId: 'd1',
      );
      final b = const AuthAuthenticated(
        token: 't1', userId: 'u1', username: 'alice', deviceId: 'd1',
      );
      final c = const AuthAuthenticated(
        token: 't2', userId: 'u1', username: 'alice', deviceId: 'd1',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('AuthExpired — properties are correct', () {
      final state = const AuthExpired();
      expect(state.isExpired, isTrue);
      expect(state.isAuthenticated, isFalse);
    });

    test('AuthLocked — properties are correct', () {
      final state = const AuthLocked();
      expect(state.isLocked, isTrue);
      expect(state.isAuthenticated, isFalse);
    });

    test('sealed class exhaustiveness — all subtypes created', () {
      // Compile-time check: the sealed class hierarchy
      final states = <AuthState>[
        const AuthUnknown(),
        const AuthUnauthenticated(),
        const AuthAuthenticating(),
        const AuthAuthenticated(
          token: 't', userId: 'u', username: 'n', deviceId: 'd',
        ),
        const AuthExpired(),
        const AuthLocked(),
      ];
      expect(states.length, equals(6));
    });
  });
}
