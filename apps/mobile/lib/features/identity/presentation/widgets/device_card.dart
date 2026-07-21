import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../models/device_identity.dart';

class DeviceCard extends StatelessWidget {
  final DeviceIdentity device;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const DeviceCard({
    super.key,
    required this.device,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: '${device.deviceName}. $_trustLabel. ${device.createdAtFormatted}',
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(HushSpacing.lg),
            child: Row(
              children: [
                _deviceIcon(cs),
                const SizedBox(width: HushSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              device.deviceName,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (device.isCurrentDevice) ...[
                            const SizedBox(width: HushSpacing.sm),
                            _currentBadge(context, cs),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        device.createdAtFormatted,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (device.trustStatus != TrustStatus.trusted || onRemove != null) ...[
                  const SizedBox(width: HushSpacing.sm),
                  _trustChip(context, cs),
                ],
                if (onRemove != null) ...[
                  const SizedBox(width: HushSpacing.sm),
                  IconButton(
                    onPressed: onRemove,
                    icon: Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 20,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    tooltip: 'Remove device',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _deviceIcon(ColorScheme cs) {
    IconData icon;
    Color color;

    switch (device.trustStatus) {
      case TrustStatus.trusted:
        icon = Icons.devices_rounded;
        color = cs.primary;
      case TrustStatus.pending:
        icon = Icons.devices_other_rounded;
        color = HushColors.secondary;
      case TrustStatus.unknown:
        icon = Icons.device_unknown_rounded;
        color = cs.onSurfaceVariant;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(HushSpacing.borderRadiusSm),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  Widget _currentBadge(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Current',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _trustChip(BuildContext context, ColorScheme cs) {
    final (label, color) = switch (device.trustStatus) {
      TrustStatus.trusted => ('Trusted', HushColors.success),
      TrustStatus.pending => ('Pending', HushColors.secondary),
      TrustStatus.unknown => ('Review', cs.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
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

  String get _trustLabel {
    switch (device.trustStatus) {
      case TrustStatus.trusted:
        return 'Trusted device';
      case TrustStatus.pending:
        return 'Pending review';
      case TrustStatus.unknown:
        return 'Needs review';
    }
  }
}
