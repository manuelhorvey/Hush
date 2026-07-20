import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';

class SecurityStatusCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isVerified;

  const SecurityStatusCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.isVerified = false,
  });

  const SecurityStatusCard.private({
    super.key,
    this.isVerified = false,
  }) : title = 'Private',
       description = 'This conversation is private. Only you and the other '
           'participants can access it.',
       icon = Icons.lock_rounded;

  const SecurityStatusCard.verified({
    super.key,
  }) : title = 'Verified',
       description = 'You have verified this person\'s identity.',
       icon = Icons.verified_rounded,
       isVerified = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: '$title. $description',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(HushSpacing.lg),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (isVerified ? HushColors.success : cs.primary)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(HushSpacing.borderRadiusSm),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isVerified ? HushColors.success : cs.primary,
              ),
            ),
            const SizedBox(width: HushSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
