import 'package:flutter/material.dart';

import '../../../../core/design_system/theme/theme.dart';
import '../../models/conversation.dart';

class ConversationCard extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final bool isSelected;

  const ConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final custom = HushCustomColors.of(context);
    final isOpen = conversation.lifecycle.isOpen;

    return Semantics(
      label: conversation.accessibilityLabel,
      child: Padding(
        padding: const EdgeInsets.only(bottom: HushSpacing.sm),
        child: AnimatedContainer(
          duration: HushMotion.normal,
          curve: HushMotion.standard,
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: isSelected
                ? cs.primaryContainer.withValues(alpha: 0.30)
                : cs.surfaceContainerLow,
            borderRadius:
                BorderRadius.circular(HushSpacing.borderRadiusMd),
            border: isSelected
                ? Border.all(
                    color: cs.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  )
                : Border.all(
                    color: Colors.transparent,
                    width: 0,
                  ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(HushSpacing.borderRadiusMd),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(HushSpacing.lg),
                child: Row(
                children: [
                  _Avatar(conversation: conversation, cs: cs, custom: custom),
                  const SizedBox(width: HushSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                conversation.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            _LifecycleBadge(
                              lifecycle: conversation.lifecycle,
                              cs: cs,
                              custom: custom,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _StatusRow(
                          conversation: conversation,
                          cs: cs,
                          custom: custom,
                          isOpen: isOpen,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),
              ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final Conversation conversation;
  final ColorScheme cs;
  final HushCustomColors custom;
  final bool isOpen;

  const _StatusRow({
    required this.conversation,
    required this.cs,
    required this.custom,
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
        );

    return Row(
      children: [
        Icon(
          conversation.isVerified
              ? Icons.verified_rounded
              : Icons.lock_rounded,
          size: 12,
          color: conversation.isVerified
              ? custom.success
              : cs.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            conversation.isVerified ? 'Verified' : 'Private',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: conversation.isVerified
                      ? custom.success
                      : cs.onSurfaceVariant,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            isOpen
                ? conversation.relativeTime
                : conversation.completedRelativeTime,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final Conversation conversation;
  final ColorScheme cs;
  final HushCustomColors custom;

  const _Avatar({
    required this.conversation,
    required this.cs,
    required this.custom,
  });

  @override
  Widget build(BuildContext context) {
    final name = conversation.displayName;
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isOpen = conversation.lifecycle.isOpen;

    return Container(
      width: HushSpacing.avatarSize,
      height: HushSpacing.avatarSize,
      decoration: BoxDecoration(
        color: isOpen
            ? (conversation.isVerified
                ? custom.success.withValues(alpha: 0.12)
                : cs.primaryContainer)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
      ),
      child: Center(
        child: Text(
          letter,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isOpen
                    ? (conversation.isVerified
                        ? custom.success
                        : cs.onPrimaryContainer)
                    : cs.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

class _LifecycleBadge extends StatelessWidget {
  final ConversationLifecycle lifecycle;
  final ColorScheme cs;
  final HushCustomColors custom;

  const _LifecycleBadge({
    required this.lifecycle,
    required this.cs,
    required this.custom,
  });

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (lifecycle) {
      ConversationLifecycle.active => (custom.success, 'Active'),
      ConversationLifecycle.waiting => (cs.secondary, 'Waiting'),
      ConversationLifecycle.completing => (cs.tertiary, 'Ending'),
      ConversationLifecycle.closed => (cs.onSurfaceVariant, 'Closed'),
      ConversationLifecycle.warning => (custom.warning, 'Review'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HushSpacing.xs,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(HushSpacing.borderRadiusFull),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
  }
}
