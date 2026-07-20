import 'package:flutter/material.dart';
import 'package:hush_mobile/theme/app_spacing.dart';

import '../../../../core/design_system/theme/hush_theme_extensions.dart';
import '../../../../core/responsive/responsive_layout.dart';

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
  })  : title = 'Private',
        description =
            'This moment is private. Only you and the other participants can access it.',
        icon = Icons.lock_rounded;

  const SecurityStatusCard.verified({super.key})
      : title = 'Verified',
        description = "You have verified this person's identity.",
        icon = Icons.verified_rounded,
        isVerified = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final custom = HushCustomColors.of(context);
    final accent = isVerified ? custom.success : cs.primary;

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
        child: ResponsiveBuilder(
          builder: (context, size) {
            if (size.isPhone) {
              return _compact(accent);
            }
            return _expanded(accent);
          },
        ),
      ),
    );
  }

  Widget _compact(Color accent) {
    return Builder(builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(accent, cs),
          const SizedBox(width: HushSpacing.md),
          Expanded(child: _textStack(context)),
        ],
      );
    });
  }

  Widget _expanded(Color accent) {
    return Builder(builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(accent, cs),
          const SizedBox(width: HushSpacing.lg),
          Expanded(child: _textStack(context)),
        ],
      );
    });
  }

  Widget _iconBox(Color accent, ColorScheme cs) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(HushSpacing.borderRadiusSm),
      ),
      child: Icon(icon, size: 20, color: accent),
    );
  }

  Widget _textStack(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: HushSpacing.xs),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
        ),
      ],
    );
  }
}
