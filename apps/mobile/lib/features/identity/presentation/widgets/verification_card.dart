import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../models/verification_state.dart';
import 'trust_indicator.dart';

class VerificationCard extends StatelessWidget {
  final VerificationState state;
  final String phrase;
  final VoidCallback? onStartVerification;
  final VoidCallback? onConfirm;

  const VerificationCard({
    super.key,
    required this.state,
    required this.phrase,
    this.onStartVerification,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Verification status: ${state.label}. Security phrase: $phrase.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(HushSpacing.lg),
        decoration: BoxDecoration(
          color: _bgColor(cs),
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
          border: Border.all(color: _borderColor(cs)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                TrustIndicator(state: state, size: 16),
                const SizedBox(width: HushSpacing.sm),
                Text(
                  state.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _stateColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: HushSpacing.md),
            Text(
              phrase,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: HushSpacing.sm),
            Text(
              'Compare this phrase with the person you are talking to.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (state == VerificationState.unknown &&
                onStartVerification != null) ...[
              const SizedBox(height: HushSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onStartVerification,
                  child: const Text('Start Verification'),
                ),
              ),
            ],
            if (state == VerificationState.pending &&
                onConfirm != null) ...[
              const SizedBox(height: HushSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Confirm Match'),
                ),
              ),
            ],
            if (state == VerificationState.verified) ...[
              const SizedBox(height: HushSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                    size: 16, color: HushColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Identity verified',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: HushColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color get _stateColor {
    switch (state) {
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

  Color _bgColor(ColorScheme cs) {
    switch (state) {
      case VerificationState.verified:
        return HushColors.successContainer;
      case VerificationState.warning:
        return HushColors.errorContainer;
      case VerificationState.pending:
        return cs.secondaryContainer.withValues(alpha: 0.3);
      case VerificationState.unknown:
        return cs.surfaceContainerHighest.withValues(alpha: 0.5);
    }
  }

  Color _borderColor(ColorScheme cs) {
    switch (state) {
      case VerificationState.verified:
        return HushColors.success.withValues(alpha: 0.3);
      case VerificationState.warning:
        return HushColors.error.withValues(alpha: 0.3);
      case VerificationState.pending:
        return HushColors.secondary.withValues(alpha: 0.3);
      case VerificationState.unknown:
        return cs.outlineVariant;
    }
  }
}
