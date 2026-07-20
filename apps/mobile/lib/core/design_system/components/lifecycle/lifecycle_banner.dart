import 'package:flutter/material.dart';

enum ConversationLifecycle {
  active,
  waiting,
  completing,
  closed,
  destroyed,
}

class LifecycleBanner extends StatelessWidget {
  final ConversationLifecycle lifecycle;

  const LifecycleBanner({
    super.key,
    this.lifecycle = ConversationLifecycle.active,
  });

  @override
  Widget build(BuildContext context) {
    if (lifecycle == ConversationLifecycle.active) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final (label, bg, fg) = switch (lifecycle) {
      ConversationLifecycle.waiting => (
        'Waiting for participants...',
        cs.secondaryContainer,
        cs.onSecondaryContainer,
      ),
      ConversationLifecycle.completing => (
        'Completing moment...',
        cs.tertiaryContainer,
        cs.onTertiaryContainer,
      ),
      ConversationLifecycle.closed => (
        'Moment completed. Messages are preserved.',
        cs.tertiaryContainer,
        cs.onTertiaryContainer,
      ),
      ConversationLifecycle.destroyed => (
        'This moment is gone.',
        cs.errorContainer,
        cs.onErrorContainer,
      ),
      ConversationLifecycle.active => ('', cs.surface, cs.onSurface),
    };

    return Semantics(
      label: label,
      liveRegion: true,
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: bg,
        child: Row(
          children: [
            Icon(_icon, size: 16, color: fg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _icon {
    switch (lifecycle) {
      case ConversationLifecycle.waiting:
        return Icons.hourglass_empty_rounded;
      case ConversationLifecycle.completing:
        return Icons.check_circle_outline_rounded;
      case ConversationLifecycle.closed:
        return Icons.check_circle_rounded;
      case ConversationLifecycle.destroyed:
        return Icons.delete_forever_rounded;
      case ConversationLifecycle.active:
        return Icons.circle;
    }
  }
}
