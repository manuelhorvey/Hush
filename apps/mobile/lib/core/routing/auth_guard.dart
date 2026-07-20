import '../../core/providers/auth_state_provider.dart';
import 'app_route.dart';

String? evaluateAuthRedirect(AuthState auth, String path) {
  if (auth.loading) return null;

  if (AppRoute.isSplash(path)) {
    return auth.isLoggedIn ? AppRoute.home : AppRoute.welcome;
  }

  if (!auth.isLoggedIn && AppRoute.isProtectedRoute(path)) {
    return AppRoute.splash;
  }

  if (auth.isLoggedIn && AppRoute.isAuthRoute(path)) {
    return AppRoute.home;
  }

  return null;
}
