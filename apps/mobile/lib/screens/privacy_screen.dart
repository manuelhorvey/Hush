import 'package:flutter/material.dart';
import '../core/design_system/components/cards/section_card.dart';
import '../core/design_system/components/navigation/hush_app_bar.dart';
import '../theme/app_spacing.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const HushAppBar(title: 'Privacy', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          HushSpacing.lg,
          HushSpacing.md,
          HushSpacing.lg,
          HushSpacing.xxl,
        ),
        children: [
          SettingsGroup(
            title: 'Privacy',
            items: [
              ListTile(
                leading: Icon(Icons.visibility_off_rounded, color: cs.primary),
                title: const Text('Screen Protection'),
                subtitle: const Text('Hide app content in app switcher'),
                trailing: Switch(value: false, onChanged: (_) {}),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Icon(Icons.notifications_off_rounded, color: cs.primary),
                title: const Text('Private Notifications'),
                subtitle: const Text('Hide message content in notifications'),
                trailing: Switch(value: true, onChanged: (_) {}),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Icon(Icons.timer_outlined, color: cs.primary),
                title: const Text('Auto-Lock'),
                subtitle: const Text('Lock app after inactivity'),
                trailing: Switch(value: false, onChanged: (_) {}),
              ),
            ],
          ),
          const SizedBox(height: HushSpacing.xxl),
          SettingsGroup(
            title: 'Data',
            items: [
              ListTile(
                leading: Icon(Icons.delete_sweep_outlined, color: cs.primary),
                title: const Text('Clear Local Data'),
                subtitle: const Text('Remove cached data from this device'),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
