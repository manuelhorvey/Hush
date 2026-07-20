import 'package:flutter/material.dart';

import '../../../../core/design_system/theme/theme.dart';

/// A lightweight, non-blocking educational card that explains privacy concepts.
///
/// Designed to be informative without creating "security walls" — the user
/// can read it and move on. Never uses cryptographic terminology.
///
/// Examples:
/// - What does "verified" mean?
/// - Why is this conversation private?
/// - How does device trust work?
class PrivacyEducationCard extends StatelessWidget {
  final String title;
  final String explanation;
  final IconData icon;
  final VoidCallback? onDismiss;
  final bool initiallyExpanded;

  const PrivacyEducationCard({
    super.key,
    required this.title,
    required this.explanation,
    required this.icon,
    this.onDismiss,
    this.initiallyExpanded = false,
  });

  /// "What does verified mean?" explanation card
  const PrivacyEducationCard.verified({
    super.key,
    this.onDismiss,
    this.initiallyExpanded = false,
  })  : title = 'What does verified mean?',
        explanation =
            'Verification helps you confirm that you are speaking with the '
            'person you expect. When you verify someone, both of you compare '
            'a shared phrase. If the phrases match, you know it\'s really them.\n\n'
            'Verification is entirely private. Hush never sees or stores your '
            'verification phrases.',
        icon = Icons.verified_outlined;

  /// "What does private mean?" explanation card
  const PrivacyEducationCard.private({
    super.key,
    this.onDismiss,
    this.initiallyExpanded = false,
  })  : title = 'What does private mean?',
        explanation =
            'Private means your conversations are only accessible to you and '
            'the people you\'re talking to. Hush cannot read your messages.\n\n'
            'Each conversation exists only for as long as you need it. When '
            'it ends, it\'s gone.',
        icon = Icons.lock_outline_rounded;

  /// "What is a trusted device?" explanation card
  const PrivacyEducationCard.deviceTrust({
    super.key,
    this.onDismiss,
    this.initiallyExpanded = false,
  })  : title = 'What is a trusted device?',
        explanation =
            'A trusted device is one that you\'ve confirmed belongs to you. '
            'Your identity exists on every device you use.\n\n'
            'Review your devices regularly to make sure only the devices you '
            'own have access.',
        icon = Icons.devices_rounded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Privacy education: $title',
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
          border: Border.all(
            color: cs.primaryContainer.withValues(alpha: 0.5),
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.fromLTRB(
            HushSpacing.lg,
            HushSpacing.sm,
            HushSpacing.sm,
            HushSpacing.sm,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            HushSpacing.lg,
            0,
            HushSpacing.lg,
            HushSpacing.lg,
          ),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Icon(
            icon,
            size: 20,
            color: cs.primary,
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onDismiss != null)
                Semantics(
                  label: 'Dismiss',
                  button: true,
                  child: IconButton(
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Dismiss',
                  ),
                ),
              Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              explanation,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onPrimaryContainer,
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
