import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/core/providers/auth_state_provider.dart';
import 'package:hush_mobile/core/routing/app_route.dart';
import 'package:hush_mobile/core/routing/auth_guard.dart';
import 'package:hush_mobile/services/auth_service.dart';

void main() {
  group('evaluateAuthRedirect', () {
    const loadingAuth = AuthState(loading: true);
    const unauthenticated = AuthState(loading: false);
    final authenticated = AuthState(
      session: SessionInfo(userId: 'u', username: 'u', token: 't'),
      loading: false,
    );

    test('returns null while auth is loading (let splash handle)', () {
      expect(evaluateAuthRedirect(loadingAuth, '/chats'), isNull);
      expect(evaluateAuthRedirect(loadingAuth, '/'), isNull);
    });

    test('redirects from splash to home when logged in', () {
      expect(evaluateAuthRedirect(authenticated, '/splash'), AppRoute.home);
    });

    test('redirects from splash to welcome when not logged in', () {
      expect(evaluateAuthRedirect(unauthenticated, '/splash'),
          AppRoute.welcome);
    });

    test('redirects unauthenticated user from protected route to splash',
        () {
      expect(evaluateAuthRedirect(unauthenticated, '/chats'),
          AppRoute.splash);
      expect(evaluateAuthRedirect(unauthenticated, '/settings'),
          AppRoute.splash);
      expect(evaluateAuthRedirect(unauthenticated, '/devices'),
          AppRoute.splash);
    });

    test('redirects unauthenticated user from conversation id to splash',
        () {
      expect(evaluateAuthRedirect(unauthenticated, '/conversation/abc123'),
          AppRoute.splash);
    });

    test('redirects authenticated user from auth route to home', () {
      expect(evaluateAuthRedirect(authenticated, '/welcome'),
          AppRoute.home);
      expect(evaluateAuthRedirect(authenticated, '/identity/create'),
          AppRoute.home);
    });

    test('lets authenticated user stay on protected routes', () {
      expect(evaluateAuthRedirect(authenticated, '/chats'), isNull);
      expect(evaluateAuthRedirect(authenticated, '/settings'), isNull);
    });

    test('lets unauthenticated user stay on welcome', () {
      expect(evaluateAuthRedirect(unauthenticated, '/welcome'), isNull);
    });

    test('redirects splash to welcome when unauthenticated', () {
      expect(evaluateAuthRedirect(unauthenticated, '/splash'),
          AppRoute.welcome);
    });
  });
}
