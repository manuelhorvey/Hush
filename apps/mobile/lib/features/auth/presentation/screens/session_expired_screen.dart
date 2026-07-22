import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/theme/theme.dart';
import '../../../../theme/app_spacing.dart';

/// Session expired screen.
///
/// Shown when the user's session has expired. Provides a gentle path
/// to re-authenticate without abrupt redirects.
///
/// Message: "Your session has ended. Please verify again."
/// Actions: Sign in again.
class SessionExpiredScreen extends ConsumerWidget {
  const SessionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Visual anchor
                Semantics(
                  label: 'Session expired',
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: cs.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.hourglass_bottom_rounded,
                      size: 40,
                      color: cs.error,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Semantics(
                  label: 'Your session has ended',
                  child: Text(
                    'Your session has ended.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),

                // Message
                Semantics(
                  label: 'Please verify again to continue',
                  child: Text(
                    'Please verify again to continue.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 32),

                // Sign in button
                SizedBox(
                  width: double.infinity,
                  height: HushSpacing.buttonHeight,
                  child: Semantics(
                    label: 'Sign in again',
                    child: FilledButton.icon(
                      onPressed: () => context.go('/login'),
                      icon: const Icon(
                        Icons.login_rounded,
                        size: 18,
                      ),
                      label: const Text('Sign in again'),
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
