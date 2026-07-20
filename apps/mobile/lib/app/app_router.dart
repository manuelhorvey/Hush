import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/messaging_service.dart';
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
import '../../screens/settings_screen.dart';
import '../../features/identity/presentation/screens/identity_create_screen.dart';
import '../../features/identity/presentation/screens/identity_profile_screen.dart';
import '../../features/identity/presentation/screens/device_management_screen.dart';
import '../../features/identity/presentation/screens/verification_screen.dart';
import '../../core/design_system/components/feedback/error_state.dart';
import '../../core/routing/app_route.dart';
import '../../core/routing/auth_guard.dart';
import '../../core/providers/auth_state_provider.dart';
import 'app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoute.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) => evaluateAuthRedirect(auth, state.uri.path),
    routes: [
      GoRoute(
        path: AppRoute.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoute.welcome,
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
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.home,
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.identity,
                builder: (_, __) => const IdentityProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.settings,
                builder: (_, __) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.conversation,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => ConversationScreen(
          conversationId: state.pathParameters['id']!,
          participants: state.extra as List<ParticipantInfo>? ?? [],
        ),
      ),
      GoRoute(
        path: AppRoute.conversationComplete,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => ConversationCompleteScreen(
          conversationTitle: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: AppRoute.conversationDestroyed,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => ConversationDestroyedScreen(
          conversationTitle: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: AppRoute.newConversation,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const NewConversationScreen(),
      ),
      GoRoute(
        path: AppRoute.devices,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const DeviceManagementScreen(),
      ),
      GoRoute(
        path: AppRoute.verification,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const VerificationScreen(),
      ),
      GoRoute(
        path: AppRoute.profile,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const IdentityProfileScreen(),
      ),
      GoRoute(
        path: AppRoute.privacy,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const PrivacyScreen(),
      ),
      GoRoute(
        path: AppRoute.security,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SecurityScreen(),
      ),
    ],
    errorBuilder: (context, state) => HushErrorState(
      title: 'Page not found',
      message: "The page '${state.uri}' doesn't exist.",
      icon: Icons.link_off_rounded,
    ),
  );
});
