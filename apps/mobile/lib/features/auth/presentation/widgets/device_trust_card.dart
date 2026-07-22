import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';
import '../../domain/entities/device_identity.dart';

/// Displays a device's identity and trust status.
///
/// Used in the device management screen to show each registered device.
/// Language: "Device trusted" rather than "Device authenticated".
class DeviceTrustCard extends StatelessWidget {
  final DeviceIdentity device;
  final VoidCallback? onTap;
  final VoidCallback? onRename;
  final VoidCallback? onRemove;

  const DeviceTrustCard({
    super.key,
    required this.device,
    this.onTap,
    this.onRename,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(HushSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Device icon
                  Semantics(
                    label: device.deviceName,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _trustColor(cs).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _trustIcon(),
                        size: 20,
                        color: _trustColor(cs),
                      ),
                    ),
                  ),
                  const SizedBox(width: HushSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.deviceName,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          device.platform,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  // Trust badge
                  Semantics(
                    label: device.trustLabel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: HushSpacing.sm,
                        vertical: HushSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: _trustColor(cs).withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(HushSpacing.borderRadiusSm),
                      ),
                      child: Text(
                        device.trustLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _trustColor(cs),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: HushSpacing.sm),
              Text(
                'Registered ${device.displayCreatedAt}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              if (onRename != null || onRemove != null) ...[
                const SizedBox(height: HushSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onRename != null)
                      TextButton.icon(
                        onPressed: onRename,
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Rename'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    if (onRemove != null)
                      TextButton.icon(
                        onPressed: onRemove,
                        icon: Icon(Icons.remove_circle_outline_rounded,
                            size: 16, color: cs.error),
                        label: Text(
                          'Remove',
                          style: TextStyle(color: cs.error),
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _trustColor(ColorScheme cs) {
    return switch (device.trustedStatus) {
      DeviceTrustStatus.trusted => Colors.green,
      DeviceTrustStatus.pending => cs.tertiary,
      DeviceTrustStatus.revoked => cs.error,
      DeviceTrustStatus.unknown => cs.onSurfaceVariant,
    };
  }

  IconData _trustIcon() {
    return switch (device.trustedStatus) {
      DeviceTrustStatus.trusted => Icons.shield_rounded,
      DeviceTrustStatus.pending => Icons.hourglass_empty_rounded,
      DeviceTrustStatus.revoked => Icons.block_rounded,
      DeviceTrustStatus.unknown => Icons.help_outline_rounded,
    };
  }
}
