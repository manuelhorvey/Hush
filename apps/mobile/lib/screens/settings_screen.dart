import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/identity/models/verification_state.dart';
import '../features/identity/presentation/screens/device_management_screen.dart';
import '../features/identity/presentation/screens/identity_profile_screen.dart';
import '../features/identity/presentation/widgets/identity_badge.dart';
import '../features/identity/presentation/widgets/trust_indicator.dart';
import '../features/identity/providers/identity_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'welcome_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer2<AuthProvider, IdentityProvider>(
      builder: (context, auth, identity, _) {
        final state = identity.userIdentity?.verificationState
            ?? VerificationState.unknown;
        final displayName = auth.username ?? '...';

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              HushSpacing.lg,
              HushSpacing.md,
              HushSpacing.lg,
              HushSpacing.xxl,
            ),
            children: [
              Semantics(
                label: 'Identity profile for $displayName',
                child: Card(
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const IdentityProfileScreen(),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(HushSpacing.lg),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                HushSpacing.borderRadiusMd,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : '?',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: cs.onPrimaryContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: HushSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    TrustIndicator(state: state, size: 10),
                                    const SizedBox(width: 4),
                                    Text(
                                      state.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: _stateColor(state),
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: HushSpacing.xl),
              Text(
                'Account',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: HushSpacing.sm),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.devices_rounded, color: cs.primary),
                      title: const Text('My Devices'),
                      trailing: Icon(Icons.chevron_right,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DeviceManagementScreen(),
                        ),
                      ),
                    ),
                    Divider(
                        height: 1,
                        indent: 56,
                        color: cs.outlineVariant),
                    ListTile(
                      leading: Icon(Icons.verified_outlined, color: cs.primary),
                      title: const Text('Verification'),
                      trailing: Icon(Icons.chevron_right,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const IdentityProfileScreen(),
                        ),
                      ),
                    ),
                    Divider(
                        height: 1,
                        indent: 56,
                        color: cs.outlineVariant),
                    ListTile(
                      leading: Icon(Icons.logout_rounded,
                          color: cs.onSurfaceVariant),
                      title: Text('Sign Out',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                      onTap: () => _logout(context, auth),
                    ),
                  ],
                ),
              ),
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
      },
    );
  }

  void _logout(BuildContext context, AuthProvider auth) async {
    final navigator = Navigator.of(context);
    await auth.logout();
    navigator.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const WelcomeScreen(),
        transitionsBuilder: (_, a, _, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (_) => false,
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
