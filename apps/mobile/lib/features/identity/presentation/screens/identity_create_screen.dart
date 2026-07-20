import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_client.dart';
import '../../../../services/crypto_service.dart';
import '../../../../services/identity_service.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../providers/identity_provider.dart';

class IdentityCreateScreen extends StatefulWidget {
  const IdentityCreateScreen({super.key});

  @override
  State<IdentityCreateScreen> createState() => _IdentityCreateScreenState();
}

class _IdentityCreateScreenState extends State<IdentityCreateScreen> {
  final _usernameController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _createIdentity() async {
    final displayName = _usernameController.text.trim();
    if (displayName.isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final identityProvider = context.read<IdentityProvider>();
      final authProvider = context.read<AuthProvider>();
      final crypto = context.read<CryptoService>();
      final identity = context.read<IdentityService>();

      final publicKey = await crypto.getPublicKeyHex();
      final session = await authProvider.register(displayName, publicKey);

      final x25519PubKey = await crypto.getX25519PublicKeyBase64();
      await identity.registerDevice(session.token, displayName, publicKey);
      await identity.storeExchangeKey(session.token, x25519PubKey);

      identityProvider.setSessionIdentity(
        userId: session.userId,
        username: session.username,
      );

      if (!mounted) return;
      context.go('/chats');
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Identity'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    size: 40,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Create your identity',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your identity stays under your control.\n'
                  'Hush does not need unnecessary personal information.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Semantics(
                  label: 'Choose your display name',
                  child: TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Display name',
                      hintText: 'Enter your name',
                      errorText: _error,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _createIdentity(),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: HushSpacing.buttonHeight,
                  child: Semantics(
                    label: _loading ? 'Creating identity' : 'Create identity',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
