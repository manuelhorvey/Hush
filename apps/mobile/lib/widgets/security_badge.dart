import 'package:flutter/material.dart';

class SecurityBadge extends StatelessWidget {
  final bool isVerified;
  final VoidCallback? onTap;

  const SecurityBadge({
    super.key,
    this.isVerified = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: isVerified ? 'Private. Verified.' : 'Private. Tap to verify.',
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVerified ? Icons.lock_rounded : Icons.lock_open_rounded,
              size: 14,
              color: isVerified ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Private',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isVerified ? cs.primary : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
