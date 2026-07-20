import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/messaging_service.dart';
import '../../screens/app_shell.dart';
import '../../screens/home_screen.dart';
import '../../screens/conversation_screen.dart';
import '../../screens/conversation_complete_screen.dart';
import '../../screens/conversation_destroyed_screen.dart';
import '../../screens/splash_screen.dart';
import '../../screens/welcome_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/new_conversation_screen.dart';
import '../../screens/privacy_screen.dart';
import '../../screens/security_screen.dart';
import '../../features/identity/presentation/screens/identity_create_screen.dart';
import '../../features/identity/presentation/screens/identity_profile_screen.dart';
import '../../features/identity/presentation/screens/device_management_screen.dart';
import '../../features/identity/presentation/screens/verification_screen.dart';
import '../../screens/settings_screen.dart';
import '../providers/auth_state_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final loggedIn = authState.isLoggedIn;
      final path = state.uri.path;

      if (authState.loading) return null;

      final isAuthRoute = path == '/welcome' ||
          path == '/login' ||
          path == '/create-identity';
      final isSplash = path == '/splash';

      if (isSplash) return loggedIn ? '/chats' : '/welcome';
      if (!loggedIn && !isAuthRoute) return '/welcome';
      if (loggedIn && isAuthRoute) return '/chats';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/create-identity',
        builder: (_, __) => const IdentityCreateScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/chats',
            pageBuilder: (_, __) => NoTransitionPage(
              child: _ShellWrapper(child: const HomeScreen()),
            ),
          ),
          GoRoute(
            path: '/identity',
            pageBuilder: (_, __) => NoTransitionPage(
              child: _ShellWrapper(child: const IdentityProfileScreen()),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (_, __) => NoTransitionPage(
              child: _ShellWrapper(child: const SettingsScreen()),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/conversation/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => ConversationScreen(
          conversationId: state.pathParameters['id']!,
          participants: state.extra as List<ParticipantInfo>? ?? [],
        ),
      ),
      GoRoute(
        path: '/conversation/:id/complete',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => ConversationCompleteScreen(
          conversationTitle: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: '/conversation/:id/destroyed',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => ConversationDestroyedScreen(
          conversationTitle: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: '/new-conversation',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const NewConversationScreen(),
      ),
      GoRoute(
        path: '/devices',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const DeviceManagementScreen(),
      ),
      GoRoute(
        path: '/verification',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const VerificationScreen(),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const IdentityProfileScreen(),
      ),
      GoRoute(
        path: '/privacy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/security',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SecurityScreen(),
      ),
    ],
  );
});

class _ShellWrapper extends StatelessWidget {
  final Widget child;
  const _ShellWrapper({required this.child});

  @override
  Widget build(BuildContext context) => child;
}
