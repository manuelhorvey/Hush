import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;

import '../../core/providers/auth_state_provider.dart';
import '../../core/providers/conversations_state_provider.dart';
import '../../core/providers/crypto_service_provider.dart';
import '../../core/providers/theme_mode_provider.dart';
import '../../core/providers/websocket_service_provider.dart';
import '../../features/identity/presentation/providers/identity_service_provider.dart';
import '../../features/identity/providers/identity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/conversations_provider.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/crypto_service.dart';
import '../../services/identity_service.dart';
import '../../services/messaging_service.dart';
import '../../services/websocket_service.dart';
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
    final wsService = WebSocketService();

    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(authService),
        messagingServiceProvider.overrideWithValue(messagingService),
        identityServiceProvider.overrideWithValue(identityService),
        cryptoServiceProvider.overrideWithValue(cryptoService),
        webSocketServiceProvider.overrideWithValue(wsService),
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
        child: _AppRoot(wsService: wsService),
      ),
    );
  }
}

class _AppRoot extends ConsumerStatefulWidget {
  final WebSocketService wsService;

  const _AppRoot({required this.wsService});

  @override
  ConsumerState<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<_AppRoot> {
  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    await ref.read(authStateProvider.notifier).init();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next.isLoggedIn && next.token != null) {
        widget.wsService.connect(next.token!);
      } else if (!next.isLoggedIn && prev?.isLoggedIn == true) {
        widget.wsService.disconnect();
      }
    });

    return MaterialApp.router(
      title: 'Hush',
      debugShowCheckedModeBanner: false,
      theme: HushTheme.light,
      darkTheme: HushTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }

  @override
  void dispose() {
    widget.wsService.dispose();
    super.dispose();
  }
}
