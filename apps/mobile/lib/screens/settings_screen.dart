import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/design_system/components/cards/section_card.dart';
import '../core/design_system/components/navigation/hush_app_bar.dart';
import '../features/identity/models/verification_state.dart';
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
          appBar: HushAppBar(title: 'Settings'),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              HushSpacing.lg,
              HushSpacing.md,
              HushSpacing.lg,
              HushSpacing.xxl,
            ),
            children: [
              SectionCard(
                leading: Semantics(
                  label: 'Avatar for $displayName',
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
                    ),
                    child: Center(
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                subtitle: Row(
                  children: [
                    TrustIndicator(state: state, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      state.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _stateColor(state),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
                onTap: () => context.go('/profile'),
              ),
              const SizedBox(height: HushSpacing.xl),
              SettingsGroup(
                title: 'Account',
                items: [
                  ListTile(
                    leading: Icon(Icons.devices_rounded, color: cs.primary),
                    title: const Text('My Devices'),
                    trailing: Icon(Icons.chevron_right,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    onTap: () => context.go('/devices'),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: Icon(Icons.verified_outlined, color: cs.primary),
                    title: const Text('Verification'),
                    trailing: Icon(Icons.chevron_right,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    onTap: () => context.go('/verification'),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: Icon(Icons.privacy_tip_outlined, color: cs.primary),
                    title: const Text('Privacy'),
                    trailing: Icon(Icons.chevron_right,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    onTap: () => context.go('/privacy'),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: Icon(Icons.security_rounded, color: cs.primary),
                    title: const Text('Security'),
                    trailing: Icon(Icons.chevron_right,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    onTap: () => context.go('/security'),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: Icon(Icons.logout_rounded, color: cs.onSurfaceVariant),
                    title: Text('Sign Out',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                    onTap: () => _logout(context, auth),
                  ),
                ],
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
