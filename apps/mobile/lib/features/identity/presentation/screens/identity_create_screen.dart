import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/theme/theme.dart';
import '../../../../core/network/network_errors.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_client.dart';
import '../../../../services/crypto_service.dart';
import '../../../../services/identity_service.dart';
import '../providers/identity_notifier.dart';

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
      // Auth & identity creation are combined in this flow:
      // 1. Register the auth session
      // 2. Register the device identity
      // 3. Store the exchange key
      // 4. Set the identity in the Riverpod notifier

      final authProvider = context.read<AuthProvider>();
      final crypto = context.read<CryptoService>();
      final identity = context.read<IdentityService>();

      final publicKey = await crypto.getPublicKeyHex();
      final session = await authProvider.register(displayName, publicKey);

      await identity.registerDevice(session.token, displayName, publicKey);

      final x25519PubKey = await crypto.getX25519PublicKeyBase64();
      await identity.storeExchangeKey(session.token, x25519PubKey);

      // Set the identity in the Riverpod notifier
      if (mounted) {
        ref.read(identityNotifierProvider.notifier).setSessionIdentity(
              userId: session.userId,
              username: session.username,
            );

        context.go('/chats');
      }
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
        title: const Text('Your Identity'),
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
                          // Shield icon
                          _ShieldIcon(cs: cs),
                          const SizedBox(height: 24),

                          // Title
                          Text(
                            'Create your private identity',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),

                          // Explanation
                          Text(
                            'You are creating your private identity. '
                            'It stays under your control.\n'
                            'Hush does not need unnecessary personal information.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.6,
                                ),
                            textAlign: TextAlign.center,
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
                            label:
                                'No phone number or contacts required.',
                            child: Container(
                              padding:
                                  const EdgeInsets.all(HushSpacing.md),
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

class _ShieldIcon extends StatelessWidget {
  final ColorScheme cs;

  const _ShieldIcon({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        Icons.shield_outlined,
        size: 40,
        color: cs.primary,
      ),
    );
  }
}
