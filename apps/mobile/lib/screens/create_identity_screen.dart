import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/crypto_service.dart';
import '../services/identity_service.dart';
import 'app_shell.dart';

class CreateIdentityScreen extends StatefulWidget {
  const CreateIdentityScreen({super.key});

  @override
  State<CreateIdentityScreen> createState() => _CreateIdentityScreenState();
}

class _CreateIdentityScreenState extends State<CreateIdentityScreen> {
  final _usernameController = TextEditingController();
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
      final crypto = context.read<CryptoService>();
      final identity = context.read<IdentityService>();
      final auth = context.read<AuthProvider>();

      final publicKey = await crypto.getPublicKeyHex();
      final session = await auth.register(username, publicKey);

      final x25519PubKey = await crypto.getX25519PublicKeyBase64();
      await identity.registerDevice(
        session.token,
        'Default Device',
        publicKey,
      );
      await identity.storeExchangeKey(session.token, x25519PubKey);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
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
      appBar: AppBar(title: const Text('Create Identity')),
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
