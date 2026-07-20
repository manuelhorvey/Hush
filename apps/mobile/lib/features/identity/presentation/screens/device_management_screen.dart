import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../widgets/empty_state.dart';
import '../../models/device_identity.dart';
import '../../providers/identity_provider.dart';
import '../widgets/device_card.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
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
    final identity = context.watch<IdentityProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
      ),
      body: identity.devices.isEmpty
          ? EmptyState(
              icon: Icons.devices_rounded,
              title: 'No devices',
              subtitle: 'Your identity is only on this device.',
              actionLabel: 'Refresh',
              onAction: _load,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  HushSpacing.lg,
                  HushSpacing.md,
                  HushSpacing.lg,
                  HushSpacing.xxl,
                ),
                itemCount: identity.devices.length + 2,
                separatorBuilder: (_, __) => const SizedBox(height: HushSpacing.sm),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildHeader(context, cs, identity);
                  }
                  if (index == 1) {
                    return _buildInfoCard(context, cs);
                  }
                  final device = identity.devices[index - 2];
                  return DeviceCard(
                    device: device,
                    onRemove: device.trustStatus != TrustStatus.trusted
                        ? () => _confirmRemove(device.deviceName)
                        : null,
                  );
                },
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs, IdentityProvider identity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HushSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trusted Devices',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${identity.devices.length} device${identity.devices.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, ColorScheme cs) {
    return Semantics(
      label: 'Your identity exists on each device you use',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(HushSpacing.md),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusSm),
          border: Border.all(
            color: cs.primaryContainer,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: cs.primary,
            ),
            const SizedBox(width: HushSpacing.sm),
            Expanded(
              child: Text(
                'Your identity exists on each device you use. '
                'Review devices regularly.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onPrimaryContainer,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(String deviceName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Device?'),
        content: Text(
          'Remove "$deviceName" from your trusted devices?\n\n'
          'This device will no longer have access to your conversations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: HushColors.error,
              foregroundColor: HushColors.onError,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
