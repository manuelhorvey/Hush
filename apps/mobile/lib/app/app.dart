import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as p;

import '../../core/config/environment.dart';
import '../../core/network/api_client.dart';
import '../../core/providers/auth_state_provider.dart';
import '../../core/providers/conversations_state_provider.dart';
import '../../core/providers/crypto_service_provider.dart';
import '../../core/providers/network_providers.dart';
import '../../core/providers/theme_mode_provider.dart';
import '../../core/providers/websocket_service_provider.dart';
import '../../core/storage/secure_storage.dart';
import '../../features/auth/data/auth_providers.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart' as domain;
import '../../features/identity/presentation/providers/identity_service_provider.dart';
import '../../features/identity/providers/identity_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/conversations_provider.dart';
import '../../services/api_client.dart' as legacy;
import '../../services/crypto_service.dart';
import '../../services/identity_service.dart';
import '../../services/messaging_service.dart';
import '../../services/notification_service.dart';
import '../../services/websocket_service.dart';
import '../../theme/app_theme.dart';

import 'app_router.dart';

class HushApp extends StatelessWidget {
  const HushApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiHost = legacy.apiHost;
    final apiIdentity = legacy.ApiClient(baseUrl: 'http://$apiHost:8082');
    final apiMessaging = legacy.ApiClient(baseUrl: 'http://$apiHost:8083');

    final storage = SecureStorageService();
    final authApiClient = ApiClient(
      config: EnvironmentConfig(
        environment: AppEnvironment.development,
        apiBaseUrl: 'http://$apiHost:8081',
        wsBaseUrl: 'ws://$apiHost:8081',
        enableLogging: true,
      ),
      storage: storage,
    );
    final authRemoteDataSource = AuthRemoteDataSourceImpl(client: authApiClient);
    final authRepository = AuthRepository(
      remoteDataSource: authRemoteDataSource,
      storage: storage,
    );
    apiIdentity.onRefreshToken = authRepository.refreshToken;
    apiMessaging.onRefreshToken = authRepository.refreshToken;

    // New domain auth layer
    final authLocalDataSource = AuthLocalDataSource(storage: storage);

    final cryptoService = CryptoService();
    final identityService = IdentityService(api: apiIdentity);
    final messagingService = MessagingService(api: apiMessaging);
    final wsService = WebSocketService();
    final notificationService = NotificationService();

    return ProviderScope(
      overrides: [
        secureStorageServiceProvider.overrideWithValue(storage),
        apiClientProvider.overrideWithValue(authApiClient),
        authRemoteDataSourceProvider.overrideWithValue(authRemoteDataSource),
        authRepositoryProvider.overrideWithValue(authRepository),
        messagingServiceProvider.overrideWithValue(messagingService),
        identityServiceProvider.overrideWithValue(identityService),
        cryptoServiceProvider.overrideWithValue(cryptoService),
        webSocketServiceProvider.overrideWithValue(wsService),

        // New domain auth layer overrides
        domain.authLocalDataSourceProvider.overrideWithValue(authLocalDataSource),
        domain.identityServiceProvider.overrideWithValue(identityService),
        domain.legacyApiClientProvider.overrideWithValue(apiIdentity),
      ],
      child: p.MultiProvider(
        providers: [
          p.Provider<CryptoService>.value(value: cryptoService),
          p.Provider<IdentityService>.value(value: identityService),
          p.Provider<MessagingService>.value(value: messagingService),

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
        child: _AppRoot(
          wsService: wsService,
          notificationService: notificationService,
        ),
      ),
    );
  }
}

class _AppRoot extends ConsumerStatefulWidget {
  final WebSocketService wsService;
  final NotificationService notificationService;

  const _AppRoot({
    required this.wsService,
    required this.notificationService,
  });

  @override
  ConsumerState<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<_AppRoot> {
  @override
  void initState() {
    super.initState();
    _initAuth();
    _initNotifications();
    _initSessionExpiryHandler();
  }

  void _initSessionExpiryHandler() {
    // Wire the 401 → refreshSession trigger.
    // When the AuthInterceptor receives a 401 and token refresh fails,
    // it fires this callback, transitioning the domain auth state to
    // AuthExpired. The auth guard then redirects to /session/expired.
    final apiClient = ref.read(apiClientProvider);
    apiClient.onSessionExpired = () {
      ref.read(domain.domainAuthStateProvider.notifier).refreshSession();
    };
  }

  Future<void> _initAuth() async {
    await ref.read(authStateProvider.notifier).init();
    await ref.read(domain.domainAuthStateProvider.notifier).init();
  }

  Future<void> _initNotifications() async {
    await widget.notificationService.initialize();
    widget.notificationService.onNotificationTap = (conversationId) {
      if (conversationId != null && mounted) {
        context.push('/conversation/$conversationId');
      }
    };
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
