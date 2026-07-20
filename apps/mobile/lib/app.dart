import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/conversations_provider.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/crypto_service.dart';
import 'services/identity_service.dart';
import 'services/messaging_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

class HushApp extends StatelessWidget {
  const HushApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiAuth = ApiClient(baseUrl: 'http://$apiHost:8081');
    final apiIdentity = ApiClient(baseUrl: 'http://$apiHost:8082');
    final apiMessaging = ApiClient(baseUrl: 'http://$apiHost:8083');

    final authService = AuthService(api: apiAuth);
    final messagingService = MessagingService(api: apiMessaging);
    final identityService = IdentityService(api: apiIdentity);

    return MultiProvider(
      providers: [
        Provider<CryptoService>.value(value: CryptoService()),
        Provider<IdentityService>.value(value: identityService),
        Provider<MessagingService>.value(value: messagingService),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(auth: authService),
        ),
        ChangeNotifierProvider<ConversationsProvider>(
          create: (_) => ConversationsProvider(messaging: messagingService),
        ),
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => ConnectivityProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Hush',
        debugShowCheckedModeBanner: false,
        theme: HushTheme.light,
        darkTheme: HushTheme.dark,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
