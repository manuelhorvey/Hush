import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// A compact inline empty section label, used inside lists when a
/// subsection (e.g. "Active Moments") has no items.
class HushEmptySection extends StatelessWidget {
  final String title;
  final String? subtitle;

  const HushEmptySection({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(
        left: HushSpacing.xs,
        top: HushSpacing.lg,
        bottom: HushSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: title,
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
