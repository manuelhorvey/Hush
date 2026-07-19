import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final auth = AuthService(
      api: ApiClient(baseUrl: 'http://10.0.2.2:8081'),
    );
    final session = await auth.getSession();
    if (mounted) {
      setState(() => _username = session?.username);
    }
  }

  Future<void> _logout() async {
    final auth = AuthService(
      api: ApiClient(baseUrl: 'http://10.0.2.2:8081'),
    );
    await auth.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_username != null ? 'Hush — $_username' : 'Hush'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: const Center(
        child: Text('No conversations yet.'),
      ),
    );
  }
}
