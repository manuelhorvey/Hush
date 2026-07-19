import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));

    final auth = AuthService(
      api: ApiClient(baseUrl: 'http://$apiHost:8081'),
    );
    final session = await auth.getSession();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => session != null ? const HomeScreen() : const WelcomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              'Hush',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
