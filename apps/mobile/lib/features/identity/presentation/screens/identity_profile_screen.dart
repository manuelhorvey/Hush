import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/theme/theme.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../models/verification_state.dart';
import '../providers/identity_notifier.dart';
import '../widgets/device_card.dart';
import '../widgets/privacy_education_card.dart';
import '../widgets/security_status_card.dart';
import '../widgets/trust_indicator.dart';

class IdentityProfileScreen extends ConsumerStatefulWidget {
  const IdentityProfileScreen({super.key});

  @override
  ConsumerState<IdentityProfileScreen> createState() =>
      _IdentityProfileScreenState();
}

class _IdentityProfileScreenState extends ConsumerState<IdentityProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDevices());
  }

  Future<void> _loadDevices() async {
    await ref.read(identityNotifierProvider.notifier).loadDevices();
  }

  @override
  Widget build(BuildContext context) {
    final identity = ref.watch(identityNotifierProvider);
    final user = identity.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity'),
        actions: [
          Semantics(
            label: 'Privacy settings',
            button: true,
            child: IconButton(
              onPressed: () => context.push('/privacy'),
              icon: const Icon(Icons.privacy_tip_outlined),
              tooltip: 'Privacy settings',
            ),
          ),
        ],
      ),
      body: ResponsiveBuilder(
        builder: (context, size) {
          return ListView(
            padding: EdgeInsets.fromLTRB(
              HushSpacing.lg,
              size.isDesktop ? HushSpacing.xl : HushSpacing.md,
              HushSpacing.lg,
              HushSpacing.xxl,
            ),
            children: [
              // Profile header
              _ProfileHeader(user: user),

              const SizedBox(height: HushSpacing.xl),

              // Security section
              _SectionHeader(title: 'Security'),
              const SizedBox(height: HushSpacing.md),
              SecurityStatusCard.private(
                isVerified: user?.verificationState ==
                    VerificationState.verified,
              ),
              const SizedBox(height: HushSpacing.sm),
              SecurityStatusCard.verified(),

              const SizedBox(height: HushSpacing.xl),

              // Verification section
              _SectionHeader(title: 'Verification'),
              const SizedBox(height: HushSpacing.md),
              _VerificationSummaryCard(
                user: user,
                onTap: () => context.push('/verification'),
              ),

              const SizedBox(height: HushSpacing.xl),

              // Devices section
              _SectionHeader(
                title: 'Devices',
                trailing: identity.devices.isNotEmpty
                    ? Semantics(
                        label: 'Manage devices',
                        button: true,
                        child: TextButton.icon(
                          onPressed: () => context.push('/devices'),
                          icon: const Icon(Icons.settings_outlined, size: 16),
                          label: const Text('Manage'),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: HushSpacing.md),
              if (identity.devices.isEmpty)
                _EmptyDevices()
              else
                ...identity.devices.take(3).map(
                      (device) => Padding(
                        padding: const EdgeInsets.only(bottom: HushSpacing.sm),
                        child: DeviceCard(device: device),
                      ),
                    ),

              if (identity.devices.length > 3) ...[
                const SizedBox(height: HushSpacing.sm),
                Center(
                  child: Semantics(
                    label: 'View all ${identity.devices.length} devices',
                    button: true,
                    child: TextButton(
                      onPressed: () => context.push('/devices'),
                      child: Text(
                        'View all ${identity.devices.length} devices',
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: HushSpacing.xxl),

              // Privacy education
              PrivacyEducationCard.private(),
              const SizedBox(height: HushSpacing.md),
              PrivacyEducationCard.verified(),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic user;

  const _ProfileHeader({this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayName = user?.displayName as String? ?? '...';
    final state = user?.verificationState as VerificationState? ??
        VerificationState.unknown;

    return Semantics(
      label: 'Profile for $displayName. ${state.label}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(HushSpacing.xl),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            // Avatar
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
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            const SizedBox(height: HushSpacing.md),

            // Display name
            Text(
              displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: HushSpacing.sm),

            // Verification status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TrustIndicator(state: state, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${state.label} Identity',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

class _VerificationSummaryCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback? onTap;

  const _VerificationSummaryCard({this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = user?.verificationState as VerificationState? ??
        VerificationState.unknown;

    return Semantics(
      label: 'Verification status: ${state.label}',
      button: true,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(HushSpacing.lg),
            child: Row(
              children: [
                TrustIndicator(state: state, size: 20),
                const SizedBox(width: HushSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.label,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _stateColor(context, state),
                                ),
                      ),
                      if (state == VerificationState.verified)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Tap to review',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                        ),
                      if (state == VerificationState.unknown)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Verify your identity to confirm who you are.',
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
                Icon(
                  Icons.chevron_right,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
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

class _EmptyDevices extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: 'No other devices',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(HushSpacing.xl),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.devices_rounded,
              size: 32,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: HushSpacing.sm),
            Text(
              'No other devices',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your identity exists on this device.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
