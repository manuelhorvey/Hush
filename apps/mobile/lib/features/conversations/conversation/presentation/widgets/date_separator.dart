import 'package:flutter/material.dart';

import '../../../../../core/design_system/theme/theme.dart';

class DateSeparator extends StatelessWidget {
  final String label;

  const DateSeparator({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Messages from $label',
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: HushSpacing.md,
          horizontal: HushSpacing.lg,
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: HushSpacing.md),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
