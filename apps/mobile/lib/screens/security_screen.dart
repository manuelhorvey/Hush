import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/design_system/components/cards/section_card.dart';
import '../core/design_system/components/navigation/hush_app_bar.dart';
import '../theme/app_spacing.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const HushAppBar(title: 'Security', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          HushSpacing.lg,
          HushSpacing.md,
          HushSpacing.lg,
          HushSpacing.xxl,
        ),
        children: [
          SettingsGroup(
            title: 'Encryption',
            items: [
              ListTile(
                leading: Icon(Icons.lock_rounded, color: cs.primary),
                title: const Text('Encryption Keys'),
                subtitle: const Text('Manage your cryptographic keys'),
                trailing: Icon(Icons.chevron_right,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Icon(Icons.vpn_key_rounded, color: cs.primary),
                title: const Text('Key Exchange'),
                subtitle: const Text('X25519 key exchange protocol'),
                trailing: Icon(Icons.chevron_right,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: HushSpacing.xxl),
          SettingsGroup(
            title: 'Verification',
            items: [
              ListTile(
                leading: Icon(Icons.verified_outlined, color: cs.primary),
                title: const Text('Verify Identity'),
                subtitle: const Text('Compare verification phrases'),
                trailing: Icon(Icons.chevron_right,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                onTap: () => context.push('/verification'),
              ),
            ],
          ),
          const SizedBox(height: HushSpacing.xxl),
          Semantics(
            label: 'Privacy information: Your data is encrypted end-to-end',
            child: Container(
              padding: const EdgeInsets.all(HushSpacing.lg),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: HushSpacing.sm),
                  Expanded(
                    child: Text(
                      'All messages are end-to-end encrypted. '
                      'Your identity is verified through cryptographic key exchange.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onPrimaryContainer,
                            height: 1.5,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
