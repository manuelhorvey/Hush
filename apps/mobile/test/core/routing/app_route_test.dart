import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/core/routing/app_route.dart';

void main() {
  group('AppRoute', () {
    test('anchor routes match constants', () {
      expect(AppRoute.splash, '/splash');
      expect(AppRoute.welcome, '/welcome');
      expect(AppRoute.identityCreate, '/identity/create');
      expect(AppRoute.home, '/chats');
      expect(AppRoute.settings, '/settings');
      expect(AppRoute.devices, '/devices');
      expect(AppRoute.verification, '/verification');
      expect(AppRoute.privacy, '/privacy');
      expect(AppRoute.security, '/security');
    });

    group('parameterized paths', () {
      test('conversationWithId returns correct path', () {
        expect(AppRoute.conversationWithId('abc123'),
            '/conversation/abc123');
      });

      test('conversationCompleteWithId returns correct path', () {
        expect(AppRoute.conversationCompleteWithId('abc123'),
            '/conversation/abc123/complete');
      });

      test('conversationDestroyedWithId returns correct path', () {
        expect(AppRoute.conversationDestroyedWithId('abc123'),
            '/conversation/abc123/destroyed');
      });
    });

    group('isAuthRoute', () {
      test('returns true for splash', () {
        expect(AppRoute.isAuthRoute('/splash'), isTrue);
      });

      test('returns true for welcome', () {
        expect(AppRoute.isAuthRoute('/welcome'), isTrue);
      });

      test('returns true for identityCreate', () {
        expect(AppRoute.isAuthRoute('/identity/create'), isTrue);
      });

      test('returns false for home', () {
        expect(AppRoute.isAuthRoute('/chats'), isFalse);
      });

      test('returns false for conversation', () {
        expect(AppRoute.isAuthRoute('/conversation/abc'), isFalse);
      });
    });

    group('isProtectedRoute', () {
      test('returns true for home', () {
        expect(AppRoute.isProtectedRoute('/chats'), isTrue);
      });

      test('returns true for privacy', () {
        expect(AppRoute.isProtectedRoute('/privacy'), isTrue);
      });

      test('returns true for settings', () {
        expect(AppRoute.isProtectedRoute('/settings'), isTrue);
      });

      test('returns true for devices', () {
        expect(AppRoute.isProtectedRoute('/devices'), isTrue);
      });

      test('returns true for conversation with id', () {
        expect(AppRoute.isProtectedRoute('/conversation/abc123'), isTrue);
      });

      test('returns false for splash', () {
        expect(AppRoute.isProtectedRoute('/splash'), isFalse);
      });

      test('returns false for welcome', () {
        expect(AppRoute.isProtectedRoute('/welcome'), isFalse);
      });
    });

    group('isSplash', () {
      test('returns true only for splash', () {
        expect(AppRoute.isSplash('/splash'), isTrue);
        expect(AppRoute.isSplash('/welcome'), isFalse);
        expect(AppRoute.isSplash('/chats'), isFalse);
      });
    });

    test('does not leak identity or message content in path', () {
      final id = AppRoute.conversationWithId('83b72');
      expect(id, isNot(contains('bob')));
      expect(id, isNot(contains('meeting')));
      expect(id, contains('83b72'));
    });
  });
}
