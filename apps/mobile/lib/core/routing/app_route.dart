abstract final class AppRoute {
  AppRoute._();

  // Auth / Onboarding routes
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String identityCreate = '/identity/create';
  static const String deviceRegistered = '/device/registered';
  static const String sessionExpired = '/session/expired';

  // Protected routes
  static const String home = '/chats';
  static const String settings = '/settings';

  // Conversations
  static const String conversation = '/conversation/:id';
  static const String conversationComplete = '/conversation/:id/complete';
  static const String conversationDestroyed = '/conversation/:id/destroyed';
  static const String newConversation = '/new-conversation';

  // Identity & Devices
  static const String devices = '/devices';
  static const String verification = '/verification';
  static const String privacy = '/privacy';
  static const String security = '/security';

  static String conversationWithId(String id) => '/conversation/$id';
  static String conversationCompleteWithId(String id) =>
      '/conversation/$id/complete';
  static String conversationDestroyedWithId(String id) =>
      '/conversation/$id/destroyed';

  // Routes accessible without authentication
  static const List<String> authRoutes = [
    splash,
    welcome,
    login,
    identityCreate,
    deviceRegistered,
    sessionExpired,
  ];

  // Routes requiring authentication
  static const List<String> protectedRoutes = [
    home,
    settings,
    newConversation,
    devices,
    verification,
    privacy,
    security,
  ];

  static bool isAuthRoute(String path) => authRoutes.any(path.startsWith);
  static bool isProtectedRoute(String path) =>
      protectedRoutes.any(path.startsWith) ||
      path.startsWith('/conversation/');
  static bool isSplash(String path) => path == splash;
}
