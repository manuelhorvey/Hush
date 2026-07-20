import 'package:flutter/material.dart';
import '../../../../../theme/app_spacing.dart';
import '../../theme/hush_theme_extensions.dart';

enum BadgeVariant { neutral, success, warning, error, info }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final custom = HushCustomColors.of(context);
    final (bg, fg) = _colors(cs, custom);

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: HushSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color) _colors(ColorScheme cs, HushCustomColors custom) {
    switch (variant) {
      case BadgeVariant.success:
        return (custom.successContainer, custom.onSuccess);
      case BadgeVariant.warning:
        return (custom.warningContainer, custom.onWarning);
      case BadgeVariant.error:
        return (cs.errorContainer, cs.onErrorContainer);
      case BadgeVariant.info:
        return (cs.secondaryContainer, cs.onSecondaryContainer);
      case BadgeVariant.neutral:
        return (cs.surfaceContainerHighest, cs.onSurfaceVariant);
    }
  }
}
