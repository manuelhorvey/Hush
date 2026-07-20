import 'package:flutter/material.dart';
import '../../../../theme/app_spacing.dart';
import '../../theme/hush_theme_extensions.dart';

class InlineError extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const InlineError({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Error: $message',
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: HushSpacing.md, vertical: HushSpacing.sm),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusSm),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 16, color: cs.onErrorContainer),
            const SizedBox(width: HushSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onErrorContainer,
                    ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: Icon(Icons.close_rounded, size: 16, color: cs.onErrorContainer),
                onPressed: onDismiss,
                visualDensity: VisualDensity.compact,
                tooltip: 'Dismiss',
              ),
          ],
        ),
      ),
    );
  }
}

class SuccessMessage extends StatelessWidget {
  final String message;

  const SuccessMessage({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final custom = HushCustomColors.of(context);

    return Semantics(
      label: 'Success: $message',
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: HushSpacing.md, vertical: HushSpacing.sm),
        decoration: BoxDecoration(
          color: custom.successContainer,
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusSm),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 16, color: custom.onSuccess),
            const SizedBox(width: HushSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: custom.onSuccess,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
