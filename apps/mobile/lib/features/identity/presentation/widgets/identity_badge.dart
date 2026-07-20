import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../models/verification_state.dart';
import 'trust_indicator.dart';

class IdentityBadge extends StatelessWidget {
  final String displayName;
  final String? subtitle;
  final VerificationState verificationState;
  final VoidCallback? onTap;
  final bool dense;

  const IdentityBadge({
    super.key,
    required this.displayName,
    this.subtitle,
    this.verificationState = VerificationState.unknown,
    this.onTap,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = verificationState.label;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!dense) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TrustIndicator(state: verificationState, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _stateColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: HushSpacing.sm),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ],
      ],
    );

    return Semantics(
      label: '$displayName. $label.',
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
              child: content,
            )
          : content,
    );
  }

  Color get _stateColor {
    switch (verificationState) {
      case VerificationState.verified:
        return HushColors.success;
      case VerificationState.warning:
        return HushColors.error;
      case VerificationState.pending:
        return HushColors.secondary;
      case VerificationState.unknown:
        return HushColors.onSurfaceVariant;
    }
  }
}
