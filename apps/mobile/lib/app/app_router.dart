import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/messaging_service.dart';
import '../../features/conversations/presentation/screens/home_screen.dart';
import '../features/conversations/conversation/presentation/screens/conversation_screen.dart';
import '../../screens/conversation_complete_screen.dart';
import '../../screens/conversation_destroyed_screen.dart';
import '../../screens/splash_screen.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/auth/presentation/screens/identity_create_screen.dart';
import '../features/auth/presentation/screens/device_registration_screen.dart';
import '../features/auth/presentation/screens/session_expired_screen.dart';
import '../../screens/login_screen.dart';
import '../features/conversations/presentation/screens/new_conversation_screen.dart';
import '../../screens/privacy_screen.dart';
import '../../screens/security_screen.dart';
import '../../screens/settings_screen.dart';
import '../../features/identity/presentation/screens/device_management_screen.dart';
import '../../features/identity/presentation/screens/verification_screen.dart';
import '../../core/design_system/components/feedback/error_state.dart';
import '../../core/routing/app_route.dart';
import '../../core/routing/auth_guard.dart';
import '../../core/providers/auth_state_provider.dart';
import '../../core/providers/conversations_state_provider.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart' as domain;
import 'app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  final domainAuth = ref.watch(domain.domainAuthStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoute.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) => evaluateAuthRedirect(
      auth,
      state.uri.path,
      isExpired: domainAuth.isExpired,
    ),
    routes: [
      GoRoute(
        path: AppRoute.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoute.welcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoute.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoute.identityCreate,
        builder: (_, _) => const IdentityCreateScreen(),
      ),
      GoRoute(
        path: AppRoute.deviceRegistered,
        builder: (_, _) => const DeviceRegistrationScreen(),
      ),
      GoRoute(
        path: AppRoute.sessionExpired,
        builder: (_, _) => const SessionExpiredScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.home,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.conversation,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final conversationId = state.pathParameters['id']!;
          final extra = state.extra;

          String resolveName() {
            if (extra is String) return extra;
            if (extra is List<ParticipantInfo> && extra.isNotEmpty) {
              return extra.first.username;
            }
            // Fallback: look up from conversations state
            try {
              final convs = ref.read(conversationsStateProvider).conversations;
              final match = convs.where((c) => c.id == conversationId).firstOrNull;
              if (match != null) {
                final other = match.participants
                    .where((p) => p.userId != auth.userId)
                    .firstOrNull;
                if (other != null) return other.username;
              }
            } catch (_) {}
            return 'Unknown';
          }

          return ConversationScreen(
            conversationId: conversationId,
            participantName: resolveName(),
          );
        },
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
        builder: (_, _) => const NewConversationScreen(),
      ),
      GoRoute(
        path: AppRoute.devices,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const DeviceManagementScreen(),
      ),
      GoRoute(
        path: AppRoute.verification,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final extra = state.extra;
          String? userId;
          if (extra is String) {
            userId = extra;
          }
          return VerificationScreen(targetUserId: userId);
        },
      ),
      GoRoute(
        path: AppRoute.settings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoute.privacy,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const PrivacyScreen(),
      ),
      GoRoute(
        path: AppRoute.security,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const SecurityScreen(),
      ),
    ],
    errorBuilder: (context, state) => HushErrorState(
      title: 'Page not found',
      message: "The page '${state.uri}' doesn't exist.",
      icon: Icons.link_off_rounded,
    ),
  );
});
