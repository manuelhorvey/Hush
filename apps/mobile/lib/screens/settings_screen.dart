import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_spacing.dart';
import 'devices_screen.dart';
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
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
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
              Container(
                padding: const EdgeInsets.all(HushSpacing.lg),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(HushSpacing.borderRadiusMd),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius:
                            BorderRadius.circular(HushSpacing.borderRadiusMd),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 24,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: HushSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.username ?? '...',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (auth.userId != null)
                            Text(
                              auth.userId!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
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
                            builder: (_) => const DevicesScreen()),
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
}
