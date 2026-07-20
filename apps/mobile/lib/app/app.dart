import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;

import '../../core/providers/auth_state_provider.dart';
import '../../core/providers/conversations_state_provider.dart';
import '../../core/providers/theme_mode_provider.dart';
import '../../features/identity/providers/identity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/conversations_provider.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/crypto_service.dart';
import '../../services/identity_service.dart';
import '../../services/messaging_service.dart';
import '../../theme/app_theme.dart';

import 'app_router.dart';

class HushApp extends StatelessWidget {
  const HushApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiAuth = ApiClient(baseUrl: 'http://$apiHost:8081');
    final apiIdentity = ApiClient(baseUrl: 'http://$apiHost:8082');
    final apiMessaging = ApiClient(baseUrl: 'http://$apiHost:8083');

    final authService = AuthService(api: apiAuth);
    final cryptoService = CryptoService();
    final identityService = IdentityService(api: apiIdentity);
    final messagingService = MessagingService(api: apiMessaging);

    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(authService),
        messagingServiceProvider.overrideWithValue(messagingService),
      ],
      child: p.MultiProvider(
        providers: [
          p.Provider<CryptoService>.value(value: cryptoService),
          p.Provider<IdentityService>.value(value: identityService),
          p.Provider<MessagingService>.value(value: messagingService),
          p.ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(auth: authService),
          ),
          p.ChangeNotifierProvider<ConversationsProvider>(
            create: (_) => ConversationsProvider(messaging: messagingService),
          ),
          p.ChangeNotifierProvider<ConnectivityProvider>(
            create: (_) => ConnectivityProvider(),
          ),
          p.ChangeNotifierProvider<IdentityProvider>(
            create: (_) => IdentityProvider(
              identity: identityService,
              crypto: cryptoService,
            ),
          ),
        ],
        child: const _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends ConsumerWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Hush',
      debugShowCheckedModeBanner: false,
      theme: HushTheme.light,
      darkTheme: HushTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
