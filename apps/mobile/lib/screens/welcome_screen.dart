import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/design_system/components/buttons/hush_button.dart';
import '../theme/app_spacing.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 48,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to Hush',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Secure, private conversations at your fingertips.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              HushButton(
                label: 'Create Identity',
                onPressed: () => context.go('/create-identity'),
                icon: Icons.person_add_rounded,
              ),
              const SizedBox(height: HushSpacing.md),
              HushOutlineButton(
                label: 'I have an identity',
                onPressed: () => context.go('/login'),
                icon: Icons.login_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
