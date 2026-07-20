import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/components/empty_state.dart';
import '../../../../core/design_system/theme/theme.dart';
import '../../../../core/providers/auth_state_provider.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../models/device_identity.dart';
import '../providers/identity_notifier.dart';
import '../providers/identity_repository_provider.dart';
import '../widgets/device_card.dart';
import '../widgets/privacy_education_card.dart';

class DeviceManagementScreen extends ConsumerStatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  ConsumerState<DeviceManagementScreen> createState() =>
      _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends ConsumerState<DeviceManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await ref.read(identityNotifierProvider.notifier).loadDevices();
  }

  Future<void> _confirmRemove(DeviceIdentity device) async {
    final cs = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Device?'),
        content: Text(
          'Remove "${device.deviceName}" from your trusted devices?\n\n'
          'This device will no longer have access to your identity.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final token = ref.read(authStateProvider).token;
      if (token != null) {
        try {
          await ref
              .read(identityRepositoryProvider)
              .removeDevice(token, device.id);
          if (mounted) {
            ref.read(identityNotifierProvider.notifier).loadDevices();
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to remove device.')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final identity = ref.watch(identityNotifierProvider);
    final devices = identity.devices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: [
          Semantics(
            label: 'Refresh devices',
            button: true,
            child: IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: ResponsiveBuilder(
        builder: (context, size) {
          if (devices.isEmpty) {
            return EmptyState(
              icon: Icons.devices_rounded,
              title: 'No devices',
              subtitle: 'Your identity is only on this device.',
              actionLabel: 'Refresh',
              onAction: _load,
            );
          }

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                HushSpacing.lg,
                size.isDesktop ? HushSpacing.xl : HushSpacing.md,
                HushSpacing.lg,
                HushSpacing.xxl,
              ),
              children: [
                // Header
                _buildHeader(cs, devices),

                const SizedBox(height: HushSpacing.lg),

                // Info card
                _buildInfoCard(cs),

                const SizedBox(height: HushSpacing.lg),

                // Device list
                ...devices.map(
                  (device) => Padding(
                    padding: const EdgeInsets.only(bottom: HushSpacing.sm),
                    child: DeviceCard(
                      device: device,
                      onRemove: device.isCurrentDevice
                          ? null
                          : () => _confirmRemove(device),
                    ),
                  ),
                ),

                const SizedBox(height: HushSpacing.xxl),

                // Privacy education
                PrivacyEducationCard.deviceTrust(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, List<DeviceIdentity> devices) {
    final trustedCount =
        devices.where((d) => d.trustStatus == TrustStatus.trusted).length;
    final needsReviewCount =
        devices.where((d) => d.trustStatus != TrustStatus.trusted).length;

    return Semantics(
      label: 'Trusted Devices. $trustedCount trusted, $needsReviewCount need review.',
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
          Row(
            children: [
              _StatChip(
                label: '$trustedCount trusted',
                color: HushCustomColors.of(context).success,
              ),
              const SizedBox(width: HushSpacing.sm),
              if (needsReviewCount > 0)
                _StatChip(
                  label: '$needsReviewCount needs review',
                  color: HushCustomColors.of(context).warning,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme cs) {
    return Semantics(
      label:
          'Your identity exists on each device you use. Review devices regularly.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(HushSpacing.md),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusSm),
          border: Border.all(
            color: cs.primaryContainer.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                'Review devices regularly to ensure only your devices '
                'have access.',
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
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HushSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(HushSpacing.borderRadiusFull),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
