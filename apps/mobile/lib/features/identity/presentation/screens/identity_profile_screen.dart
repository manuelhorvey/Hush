import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../widgets/empty_state.dart';
import '../../providers/identity_provider.dart';
import '../widgets/device_card.dart';
import '../widgets/identity_badge.dart';
import '../widgets/security_status_card.dart';
import '../widgets/trust_indicator.dart';
import '../../models/verification_state.dart';
import 'device_management_screen.dart';
import 'verification_screen.dart';

class IdentityProfileScreen extends StatefulWidget {
  const IdentityProfileScreen({super.key});

  @override
  State<IdentityProfileScreen> createState() => _IdentityProfileScreenState();
}

class _IdentityProfileScreenState extends State<IdentityProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    await context.read<IdentityProvider>().loadDevices(token);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final identity = context.watch<IdentityProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          HushSpacing.lg,
          HushSpacing.md,
          HushSpacing.lg,
          HushSpacing.xxl,
        ),
        children: [
          _buildProfileHeader(context, cs, auth, identity),
          const SizedBox(height: HushSpacing.xl),
          _buildSection(
            context,
            title: 'Security',
            children: [
              SecurityStatusCard.private(isVerified: identity.userIdentity?.verificationState == VerificationState.verified),
              const SizedBox(height: HushSpacing.sm),
              SecurityStatusCard.verified(),
            ],
          ),
          const SizedBox(height: HushSpacing.xl),
          _buildSection(
            context,
            title: 'Verification',
            children: [
              _buildVerificationCard(context, identity),
            ],
          ),
          const SizedBox(height: HushSpacing.xl),
          _buildSection(
            context,
            title: 'Devices (${identity.devices.length})',
            trailing: ActionChip(
              label: const Text('Manage'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DeviceManagementScreen(),
                ),
              ),
            ),
            children: identity.devices.isEmpty
                ? [
                    EmptyState(
                      icon: Icons.devices_rounded,
                      title: 'No other devices',
                      subtitle: 'Your identity exists on this device.',
                    ),
                  ]
                : identity.devices.take(3).map((device) => Padding(
                      padding: const EdgeInsets.only(bottom: HushSpacing.sm),
                      child: DeviceCard(device: device),
                    )).toList(),
          ),
          const SizedBox(height: HushSpacing.xxl),
          _buildPrivacyInfo(context, cs),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    ColorScheme cs,
    AuthProvider auth,
    IdentityProvider identity,
  ) {
    final displayName = auth.username ?? '...';
    final state = identity.userIdentity?.verificationState
        ?? VerificationState.unknown;

    return Semantics(
      label: 'Profile for $displayName. ${state.label}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(HushSpacing.xl),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusLg),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
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
                  state.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _stateColor(state),
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

  Widget _buildSection(
    BuildContext context, {
    required String title,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: HushSpacing.md),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildVerificationCard(BuildContext context, IdentityProvider identity) {
    final state = identity.userIdentity?.verificationState
        ?? VerificationState.unknown;
    final phrase = identity.verificationPhrase;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VerificationScreen(
              phrase: phrase,
              initialState: state,
            ),
          ),
        ),
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _stateColor(state),
                      ),
                    ),
                    if (state == VerificationState.verified)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Tap to review',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyInfo(BuildContext context, ColorScheme cs) {
    return Semantics(
      label: 'Privacy information',
      child: Container(
        padding: const EdgeInsets.all(HushSpacing.lg),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              size: 18,
              color: cs.primary,
            ),
            const SizedBox(width: HushSpacing.sm),
            Expanded(
              child: Text(
                'Your identity stays under your control. '
                'Hush does not need unnecessary personal information.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onPrimaryContainer,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _stateColor(VerificationState state) {
    switch (state) {
      case VerificationState.verified:
        return HushColors.success;
      case VerificationState.warning:
        return HushColors.error;
      case VerificationState.pending:
        return HushColors.secondary;
      case VerificationState.unknown:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
}
