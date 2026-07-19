import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class CreateIdentityScreen extends StatefulWidget {
  const CreateIdentityScreen({super.key});

  @override
  State<CreateIdentityScreen> createState() => _CreateIdentityScreenState();
}

class _CreateIdentityScreenState extends State<CreateIdentityScreen> {
  final _usernameController = TextEditingController();
  final _authService = AuthService(
    api: ApiClient(baseUrl: 'http://10.0.2.2:8081'),
  );
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _createIdentity() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _error = 'Please enter a username.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final publicKey = _generatePlaceholderKey();
      await _authService.register(username, publicKey);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Connection failed. Check that the server is running.';
        _loading = false;
      });
    }
  }

  String _generatePlaceholderKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Identity'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose a username',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: const OutlineInputBorder(),
                  errorText: _error,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _createIdentity(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _createIdentity,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create Identity'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
