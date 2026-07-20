abstract final class AppRoute {
  AppRoute._();

  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String identityCreate = '/identity/create';

  static const String home = '/chats';
  static const String identity = '/identity';
  static const String settings = '/settings';

  static const String conversation = '/conversation/:id';
  static const String conversationComplete = '/conversation/:id/complete';
  static const String conversationDestroyed = '/conversation/:id/destroyed';
  static const String newConversation = '/new-conversation';

  static const String devices = '/devices';
  static const String verification = '/verification';
  static const String privacy = '/privacy';
  static const String security = '/security';
  static const String profile = '/profile';

  static String conversationWithId(String id) => '/conversation/$id';
  static String conversationCompleteWithId(String id) =>
      '/conversation/$id/complete';
  static String conversationDestroyedWithId(String id) =>
      '/conversation/$id/destroyed';

  static const List<String> authRoutes = [
    splash,
    welcome,
    identityCreate,
  ];

  static const List<String> protectedRoutes = [
    home,
    identity,
    settings,
    newConversation,
    devices,
    verification,
    privacy,
    security,
    profile,
  ];

  static bool isAuthRoute(String path) => authRoutes.any(path.startsWith);
  static bool isProtectedRoute(String path) =>
      protectedRoutes.any(path.startsWith) ||
      path.startsWith('/conversation/');
  static bool isSplash(String path) => path == splash;
}
