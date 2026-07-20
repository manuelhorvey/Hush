import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
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
    final (color, icon, label) = switch (state) {
      VerificationState.verified => (
        HushColors.success,
        Icons.verified_rounded,
        'Verified',
      ),
      VerificationState.pending => (
        HushColors.secondary,
        Icons.hourglass_empty_rounded,
        'Pending',
      ),
      VerificationState.warning => (
        HushColors.error,
        Icons.warning_rounded,
        'Warning',
      ),
      VerificationState.unknown => (
        HushColors.onSurfaceVariant,
        Icons.help_outline_rounded,
        'Unknown',
      ),
    };

    return Semantics(
      label: 'Trust status: $label',
      child: Container(
        width: size + 4,
        height: size + 4,
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
