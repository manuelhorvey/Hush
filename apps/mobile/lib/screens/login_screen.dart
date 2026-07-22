import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/design_system/components/buttons/hush_button.dart';
import '../core/design_system/components/inputs/hush_text_field.dart';
import '../core/network/network_errors.dart';
import '../core/providers/auth_state_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _error = 'Please enter your username.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      await ref.read(authStateProvider.notifier).login(username);
      if (!mounted) return;
      context.go('/chats');
    } on NetworkException catch (e) {
      setState(() { _error = e.userFacingMessage; _loading = false; });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Go back',
          onPressed: () => context.go('/welcome'),
        ),
        title: const Text('Login'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              HushTextField(
                controller: _usernameController,
                label: 'Username',
                error: _error,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 16),
              HushButton(
                label: 'Login',
                loading: _loading,
                onPressed: _login,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
