import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_system/components/cards/section_card.dart';
import '../core/design_system/theme/theme.dart';
import '../core/providers/auth_state_provider.dart';
import '../features/identity/models/verification_state.dart';
import '../features/identity/presentation/providers/identity_notifier.dart';
import '../features/identity/presentation/widgets/privacy_education_card.dart';
import '../features/identity/presentation/widgets/security_status_card.dart';
import '../features/identity/presentation/widgets/trust_indicator.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(identityNotifierProvider.notifier).loadDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final identity = ref.watch(identityNotifierProvider);
    final auth = ref.watch(authStateProvider);
    final user = identity.user;
    final displayName = auth.username ?? user?.displayName ?? '...';
    final state = user?.verificationState ?? VerificationState.unknown;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          HushSpacing.lg,
          HushSpacing.md,
          HushSpacing.lg,
          HushSpacing.xxl,
        ),
        children: [
          _ProfileHeader(displayName: displayName, state: state),
          const SizedBox(height: HushSpacing.xl),
          _SectionHeader(title: 'Security'),
          const SizedBox(height: HushSpacing.md),
          SecurityStatusCard.private(),
          const SizedBox(height: HushSpacing.sm),
          SecurityStatusCard.verified(),
          const SizedBox(height: HushSpacing.xl),
          _SectionHeader(title: 'Devices'),
          const SizedBox(height: HushSpacing.md),
          Semantics(
            label: 'Manage devices',
            button: true,
            child: Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.devices_rounded, color: cs.primary),
                title: Text(
                  identity.devices.isNotEmpty
                      ? '${identity.devices.length} ${identity.devices.length == 1 ? 'device' : 'devices'}'
                      : 'No other devices',
                ),
                subtitle: Text(
                  identity.devices.isNotEmpty
                      ? 'Tap to manage'
                      : 'Your identity exists on this device.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                onTap: () => context.push('/devices'),
              ),
            ),
          ),
          const SizedBox(height: HushSpacing.xl),
          SettingsGroup(
            title: 'Account',
            items: [
              ListTile(
                leading:
                    Icon(Icons.verified_outlined, color: cs.primary),
                title: const Text('Verification'),
                trailing: Icon(Icons.chevron_right,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                onTap: () => context.push('/verification'),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading:
                    Icon(Icons.privacy_tip_outlined, color: cs.primary),
                title: const Text('Privacy'),
                trailing: Icon(Icons.chevron_right,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                onTap: () => context.push('/privacy'),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading:
                    Icon(Icons.security_rounded, color: cs.primary),
                title: const Text('Security'),
                trailing: Icon(Icons.chevron_right,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                onTap: () => context.push('/security'),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Icon(Icons.logout_rounded,
                    color: cs.onSurfaceVariant),
                title: Text('Sign Out',
                    style: TextStyle(color: cs.onSurfaceVariant)),
                onTap: () => _logout(),
              ),
            ],
          ),
          const SizedBox(height: HushSpacing.xl),
          PrivacyEducationCard.private(),
          const SizedBox(height: HushSpacing.md),
          PrivacyEducationCard.verified(),
          const SizedBox(height: HushSpacing.xxl),
          Center(
            child: Text(
              'Hush v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) {
      context.go('/welcome');
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final VerificationState state;

  const _ProfileHeader({
    required this.displayName,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Profile for $displayName. ${state.label}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(HushSpacing.xl),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius:
              BorderRadius.circular(HushSpacing.borderRadiusMd),
          border:
              Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primaryContainer,
                    cs.primary.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : '?',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            const SizedBox(height: HushSpacing.md),
            Text(
              displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: HushSpacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TrustIndicator(state: state, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${state.label} Identity',
                  style:
                      Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: _stateColor(context, state),
                            fontWeight: FontWeight.w600,
                          ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _stateColor(BuildContext context, VerificationState state) {
    switch (state) {
      case VerificationState.verified:
        return HushCustomColors.of(context).success;
      case VerificationState.warning:
        return HushCustomColors.of(context).warning;
      case VerificationState.pending:
        return Theme.of(context).colorScheme.secondary;
      case VerificationState.unknown:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
