import 'package:flutter/material.dart';

import '../../../../core/design_system/theme/theme.dart';
import '../../models/verification_state.dart';

class TrustIndicator extends StatelessWidget {
  final VerificationState state;
  final double size;

  const TrustIndicator({
    super.key,
    required this.state,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    final custom = HushCustomColors.of(context);
    final cs = Theme.of(context).colorScheme;

    final (color, icon, label) = switch (state) {
      VerificationState.verified => (
          custom.success,
          Icons.verified_rounded,
          'Verified',
        ),
      VerificationState.pending => (
          cs.secondary,
          Icons.hourglass_empty_rounded,
          'Pending',
        ),
      VerificationState.warning => (
          custom.warning,
          Icons.warning_rounded,
          'Warning',
        ),
      VerificationState.unknown => (
          cs.onSurfaceVariant,
          Icons.help_outline_rounded,
          'Not verified yet',
        ),
    };

    return Semantics(
      label: 'Trust status: $label',
      child: Container(
        width: size + 6,
        height: size + 6,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: size,
          color: color,
        ),
      ),
    );
  }
}

class TrustPill extends StatelessWidget {
  final VerificationState state;

  const TrustPill({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final custom = HushCustomColors.of(context);
    final cs = Theme.of(context).colorScheme;

    final (color, label) = switch (state) {
      VerificationState.verified => (custom.success, 'Verified'),
      VerificationState.pending => (cs.secondary, 'Pending'),
      VerificationState.warning => (custom.warning, 'Needs review'),
      VerificationState.unknown => (cs.onSurfaceVariant, 'Not verified yet'),
    };

    return Semantics(
      label: 'Trust status: $label',
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: HushSpacing.md,
          vertical: HushSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(HushRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TrustIndicator(state: state, size: 12),
            const SizedBox(width: HushSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
