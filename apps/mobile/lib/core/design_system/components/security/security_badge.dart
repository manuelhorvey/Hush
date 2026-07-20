import 'package:flutter/material.dart';
import '../../../../theme/app_spacing.dart';
import '../../theme/hush_theme_extensions.dart';

enum SecurityBadgeVariant { private, verified, warning }

class SecurityBadge extends StatelessWidget {
  final SecurityBadgeVariant variant;

  const SecurityBadge({
    super.key,
    this.variant = SecurityBadgeVariant.private,
  });

  const SecurityBadge.private({super.key}) : variant = SecurityBadgeVariant.private;
  const SecurityBadge.verified({super.key}) : variant = SecurityBadgeVariant.verified;
  const SecurityBadge.warning({super.key}) : variant = SecurityBadgeVariant.warning;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final custom = HushCustomColors.of(context);
    final (label, icon, bg, fg) = switch (variant) {
      SecurityBadgeVariant.private => (
        'Private',
        Icons.lock_rounded,
        cs.primaryContainer,
        cs.onPrimaryContainer,
      ),
      SecurityBadgeVariant.verified => (
        'Verified',
        Icons.verified_rounded,
        custom.successContainer,
        custom.onSuccess,
      ),
      SecurityBadgeVariant.warning => (
        'Warning',
        Icons.warning_rounded,
        custom.warningContainer,
        custom.onWarning,
      ),
    };

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
