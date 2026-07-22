import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive_layout.dart';
import '../../../../theme/app_spacing.dart';

/// Welcome screen — the first thing a new user sees.
///
/// Design principles:
/// - Do not oversell. Let the product speak.
/// - Minimal friction. One clear call to action.
/// - "Private conversations that naturally end."
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ResponsiveBuilder(
                  builder: (context, size) {
                    final contentWidth = size.isDesktop || size.isTablet
                        ? 420.0
                        : double.infinity;
                    return SizedBox(
                      width: contentWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 48),

                          // App icon / visual anchor
                          Semantics(
                            label: 'Hush — private conversations',
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    cs.primaryContainer,
                                    cs.primary.withValues(alpha: 0.3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                Icons.shield_outlined,
                                size: 48,
                                color: cs.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Tagline
                          Semantics(
                            label: 'Private conversations that naturally end',
                            child: Text(
                              'Private conversations\nthat naturally end.',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                    letterSpacing: -0.5,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Subtitle
                          Semantics(
                            label:
                                'No phone number or email required. Your identity is yours.',
                            child: Text(
                              'No phone number or email required.\nYour identity is yours.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Primary CTA — Create Identity
                          Semantics(
                            label: 'Create your identity',
                            child: SizedBox(
                              width: double.infinity,
                              height: HushSpacing.buttonHeight,
                              child: FilledButton.icon(
                                onPressed: () => context.go('/identity/create'),
                                icon: const Icon(
                                  Icons.person_add_rounded,
                                  size: 18,
                                ),
                                label: const Text('Create Identity'),
                              ),
                            ),
                          ),

                          const SizedBox(height: HushSpacing.md),

                          // Secondary CTA — I have an identity
                          Semantics(
                            label: 'Sign in with existing identity',
                            child: SizedBox(
                              width: double.infinity,
                              height: HushSpacing.buttonHeight,
                              child: OutlinedButton.icon(
                                onPressed: () => context.go('/login'),
                                icon: const Icon(
                                  Icons.login_rounded,
                                  size: 18,
                                ),
                                label: const Text('I have an identity'),
                              ),
                            ),
                          ),

                          const SizedBox(height: 64),

                          // Privacy reassurance
                          Semantics(
                            label:
                                'No personal data stored. Device-based identity only.',
                            child: Container(
                              padding: const EdgeInsets.all(HushSpacing.md),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest
                                    .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(
                                    HushSpacing.borderRadiusSm),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.privacy_tip_outlined,
                                    size: 16,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: HushSpacing.sm),
                                  Text(
                                    'No personal data stored.\nDevice-based identity only.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: cs.onSurfaceVariant,
                                          height: 1.3,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
