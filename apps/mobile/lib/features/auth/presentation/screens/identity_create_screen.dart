import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/theme/theme.dart';
import '../../../../core/network/network_errors.dart';
import '../../../../core/providers/crypto_service_provider.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../services/api_client.dart';
import '../../../../services/identity_service.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/auth_state.dart';
import '../providers/auth_state_provider.dart';

/// Identity creation screen.
///
/// Combined flow: register auth session + register device + store exchange key.
/// The user provides only a display name — no email, no phone, no password.
///
/// Design: trust starts here. This is the user's first interaction with
/// their identity on this device. Keep it simple, feel safe.
class IdentityCreateScreen extends ConsumerStatefulWidget {
  const IdentityCreateScreen({super.key});

  @override
  ConsumerState<IdentityCreateScreen> createState() =>
      _IdentityCreateScreenState();
}

class _IdentityCreateScreenState extends ConsumerState<IdentityCreateScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  String? _error;
  bool _loading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: HushMotion.normal,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: HushMotion.decelerate,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _createIdentity() async {
    final displayName = _nameController.text.trim();
    if (displayName.isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      // Step 1: Register auth session
      final crypto = ref.read(cryptoServiceProvider);
      final publicKey = await crypto.getPublicKeyHex();
      final authNotifier = ref.read(domainAuthStateProvider.notifier);
      final authState = await authNotifier.register(
        username: displayName,
        publicKey: publicKey,
      );

      // Extract the token from the authenticated state
      final token = authState is AuthAuthenticated ? authState.token : null;
      if (token == null) throw Exception('Registration failed');

      // Step 2: Register device
      final identity = ref.read(identityServiceProvider);
      await identity.registerDevice(token, displayName, publicKey);

      // Step 3: Store exchange key (with retry)
      final x25519PubKey = await crypto.getX25519PublicKeyBase64();

      bool keyStored = false;
      for (int attempt = 0; attempt < 3 && !keyStored; attempt++) {
        try {
          await identity.storeExchangeKey(token, x25519PubKey);
          keyStored = true;
          debugPrint('[Auth] Exchange key stored successfully');
        } catch (e) {
          debugPrint('[Auth] storeExchangeKey attempt $attempt failed: $e');
          if (attempt < 2) {
            await Future.delayed(
              Duration(milliseconds: 500 * (attempt + 1)),
            );
          }
        }
      }
      if (!keyStored) {
        debugPrint(
            '[Auth] WARNING: exchange key may not be stored on server');
      }

      if (!mounted) return;

      // Navigate to device confirmation instead of directly to chats
      context.go('/device/registered');
    } on NetworkException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.userFacingMessage;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Connection failed. Check that the server is running.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: 'Go back',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Go back',
            onPressed: () => context.go('/welcome'),
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ResponsiveBuilder(
                builder: (context, size) {
                  final contentWidth = size.isDesktop || size.isTablet
                      ? 480.0
                      : double.infinity;
                  return Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Visual anchor
                          Semantics(
                            label: 'Identity',
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    cs.primaryContainer,
                                    cs.primary.withValues(alpha: 0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.person_outline_rounded,
                                size: 40,
                                color: cs.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Title
                          Semantics(
                            label: 'Create your private identity',
                            child: Text(
                              'Create your private identity',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Explanation
                          Semantics(
                            label:
                                'You are creating your private identity. It stays under your control. Hush does not need unnecessary personal information.',
                            child: Text(
                              'You are creating your private identity. '
                              'It stays under your control.\n'
                              'No email. No phone number. Just you.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    height: 1.6,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Display name field
                          Semantics(
                            label: 'Choose your display name',
                            child: TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Display name',
                                hintText: 'Enter your name',
                                errorText: _error,
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  size: 20,
                                ),
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted:
                                  _loading ? null : (_) => _createIdentity(),
                              textCapitalization: TextCapitalization.words,
                              enabled: !_loading,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Create button
                          SizedBox(
                            width: double.infinity,
                            height: HushSpacing.buttonHeight,
                            child: Semantics(
                              label: _loading
                                  ? 'Creating your identity'
                                  : 'Create your identity',
                              child: FilledButton(
                                onPressed: _loading ? null : _createIdentity,
                                child: AnimatedSwitcher(
                                  duration: HushMotion.fast,
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
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
                          ),
                          const SizedBox(height: 24),

                          // Privacy reassurance
                          Semantics(
                            label: 'No phone number or contacts required',
                            child: Container(
                              padding: const EdgeInsets.all(HushSpacing.md),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(
                                    HushSpacing.borderRadiusSm),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.privacy_tip_outlined,
                                    size: 16,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: HushSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      'No phone number or contacts required.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
