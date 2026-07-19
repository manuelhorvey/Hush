import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/crypto_service.dart';
import '../services/identity_service.dart';
import 'home_screen.dart';

class CreateIdentityScreen extends StatefulWidget {
  const CreateIdentityScreen({super.key});

  @override
  State<CreateIdentityScreen> createState() => _CreateIdentityScreenState();
}

class _CreateIdentityScreenState extends State<CreateIdentityScreen> {
  final _usernameController = TextEditingController();
  final _authService = AuthService(
    api: ApiClient(baseUrl: 'http://$apiHost:8081'),
  );
  final _identityService = IdentityService(
    api: ApiClient(baseUrl: 'http://$apiHost:8082'),
  );
  final _crypto = CryptoService();
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
      final publicKey = await _crypto.getPublicKeyHex();
      final session = await _authService.register(username, publicKey);

      await _identityService.registerDevice(
        session.token,
        'Default Device',
        publicKey,
      );

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
